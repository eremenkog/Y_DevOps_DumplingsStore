
# Novaya Kompaniya [NK] Store aka Пельменная №2

Итоговый проект курса «DevOps для эксплуатации и разработки» от Яндекс.Практикум.
Нижеописанное по сути является пояснительной запиской и чек-листом для проверяющего. Ссылки актуальны на момент сдачи проекта (07.2023)

<img width="900" alt="image" src="https://private-user-images.githubusercontent.com/110383560/330426215-8a88e4f4-9c7f-4687-97f7-d11b6424d4b4.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3MTU2OTAxODYsIm5iZiI6MTcxNTY4OTg4NiwicGF0aCI6Ii8xMTAzODM1NjAvMzMwNDI2MjE1LThhODhlNGY0LTljN2YtNDY4Ny05N2Y3LWQxMWI2NDI0ZDRiNC5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjQwNTE0JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI0MDUxNFQxMjMxMjZaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT0yZjA3ODkzZmYxMDkxYzFkNThkZjFjYzM3ZWQ4MGNiMzNjNjgzMmQyODI3M2NiYWQ4NTg5MWUyNzRlODg5YjgwJlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCZhY3Rvcl9pZD0wJmtleV9pZD0wJnJlcG9faWQ9MCJ9.--7oOAepwc_konpv0-TRDNWQu7ehV-ji4wUdxCsNDLI">

## Technologies used
* Frontend – Javascript, Vue.
* Backend  – Go
* Platform resources - Terraform
* Deploy and expose - K8S, [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)
* Artifact storage - [Nexus](https://nexus.k8s.praktikum-services.tech/repository/eremenko-grigorii-dumplings-store-helm/), [Gitlab Container Registry](https://gitlab.praktikum-services.ru/std-014-19/nk-dumplings/container_registry), [Yandex S3]((https://cloud.yandex.ru/services/storage/))
* CI\CD - [Gitlab](https://gitlab.praktikum-services.ru/std-014-19/nk-dumplings)
* SAST - Gitlab, Sonarqube ([Frontend](https://sonarqube.praktikum-services.ru/dashboard?id=14_GRIGORIIEREMENKO__DUMPLINGS_FRONTEND), [Backend](https://sonarqube.praktikum-services.ru/dashboard?id=14_GRIGORIIEREMENKO__DUMPLINGS_BACKEND))
* Container - Docker
* Monitoring -  [Prometheus](https://prometheus.nk-dumplings.ru/), [Grafana](https://grafana.nk-dumplings.ru/), Loki

## Frontend

```bash
npm install
NODE_ENV=production VUE_APP_API_URL=http://localhost:8081 npm run serve
```

## Backend

```bash
go run ./cmd/api
go test -v ./... 
```

## CI/CD

- используется единый [репозиторий](https://gitlab.praktikum-services.ru/std-014-19/nk-dumplings)
- развертывание приложение осуществляется с использованием [Downstream pipeline](https://docs.gitlab.com/ee/ci/pipelines/downstream_pipelines.html#parent-child-pipelines) 
- при изменениях в соответствующих директориях триггерятся pipeline для backend, frontend и infrastructure
- backend и frontend проходят этапы сборки, тестирования, релиза, деплоя в dev-окружение (docker-compose) и prod-окружение (k8s)
- helm-pipeline проходит этапы релиза и деплоя в prod-окружение (k8s)
- trunk-based development

## Versioning

#- [SemVer 2.0.0](https://semver.org/lang/ru/)
- мажорные и минорные версии приложения изменяются вручную в файлах `backend/.gitlab-ci.yaml` и `frontend/.gitlab-ci.yaml` в переменной `VERSION`
- патч-версии изменяются автоматически на основе переменной `CI_PIPELINE_ID`
- для инфраструктуры версия приложения изменяется вручную в чарте `infrastructure/helm/Chart.yaml`
- есть возможность выкатить конкретные версии фронта и бэка передав параметры $FRONTEND_VERSION и $BACKEND_VERSION. В ином случае деплоится latest.

## Инициализация инфраструктуры k8s

- клонировать репозиторий на машину с установленным terraform и yc
- через консоль Yandex Cloud создать сервисный аккаунт с ролью `editor`, получить статический ключ доступа, сохранить секретный ключ в файле `infrastructure/terraform/backend.tfvars`
- получить [iam-token](https://cloud.yandex.ru/docs/iam/operations/iam-token/create), сохранить в файле `infrastructure/terraform/secret.tfvars`
- через консоль Yandex Cloud создать Object Storage, внести параметры подключения в файл `infrastructure/terraform/provider.tf`
- выполнить следующие команды:

```
cd infrastructure/terraform
terraform init -backend-config=backend.tfvars
terraform apply -var-file="secret.tfvars"
```

## Деплой в k8s

```
# создаем базовый namespace
kubectl create namespace nk

# сохраняем креды для docker-registry
kubectl create secret generic -n nk docker-dumplings-config-secret --from-file=.dockerconfigjson="/home/user/.docker/config.json" --type=kubernetes.io/dockerconfigjson 

# устанавливаем приложение, указав версии backend и frontend
cd infrastructure/helm/
helm dependency build
helm upgrade --install --atomic -n nk nk .

# смотрим IP load balancer, прописываем А-записи для приложения и мониторинга
kubectl get svc

# созданной зоне DNS выписываем сертификат LetsEncrypt на домены nk-dumplings.ru и grafana.nk-dumplings.ru
# секрет, содержащий сертификат и закрытый ключ должен иметь имя k8s-secret
```

## Monitoring

Креды по умолчанию (admin | prom-operator) хранятся в секрете {{ .ReleaseName }}-grafana
Значения по умолчанию можно изменить передав ключи при установке helm-chart'a


## [Чек-лист для проверки]
|  |   |    |
|----|---|----|
| Задача | Статус | Комментарий
|Код хранится в GitLab с использованием любого git-flow | Выполнено |
|В проекте присутствует .gitlab-ci.yml, в котором описаны шаги сборки| Выполнено  |
|Артефакты сборки (бинарные файлы, docker-образы или др.) публикуются в систему хранения (Nexus или аналоги)| Выполнено  |
|Артефакты сборки версионируются| Выполнено |
|Написаны Dockerfile'ы для сборки Docker-образов бэкенда и фронтенда| Выполнено  |
| Бэкенд: бинарный файл Go в Docker-образе | Выполнено  |
| Фронтенд: HTML-страница раздаётся с Nginx | Выполнено  |
| В GitLab CI описан шаг сборки и публикации артефактов | Выполнено  |
| В GitLab CI описан шаг тестирования   |  Выполнено |
|  В GitLab CI описан шаг деплоя |  Выполнено | Поддерживается деплой на тестовую ВМ. В проде деплоим сразу в k8s
| Развёрнут Kubernetes-кластер в облаке  |  Выполнено |
|  Kubernetes-кластер описан в виде кода, и код хранится в репозитории GitLab | Выполнено  |
|  Конфигурация всех необходимых ресурсов описана согласно IaC  |  Выполнено | 
| Состояние Terraform'а хранится в S3 | Выполнено  |
| Картинки, которые использует сайт, или другие небинарные файлы, необходимые для работы, хранятся в S3  | Выполнено  |
| Секреты не хранятся в открытом виде  | Выполнено | Используются маскируемые GitLab Variables, секреты k8s, yandex object storage
| Написаны Kubernetes-манифесты для публикации приложения  | Выполнено  |
| Написан Helm-чарт для публикации приложения | Выполнено |
| Helm-чарты публикуются и версионируются в Nexus  |  Выполнено  |
| Приложение подключено к системам логирования и мониторинга  | Выполнено  |
| Есть дашборд, в котором можно посмотреть логи и состояние приложения  | Выполнено |
