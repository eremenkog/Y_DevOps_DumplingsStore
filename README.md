# Novaya Kompaniya [NK] Store aka Пельменная №2
## [NK-Dumplings](https://nk-dumplings.ru)

<img width="900" alt="image" src="https://storage.yandexcloud.net/nk-dumpling-bucket/monitoring/Homepage.png">

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

## Infrastructure

- код ---> [Gitlab](https://gitlab.praktikum-services.ru/std-014-19/nk-dumplings)
- helm-charts ---> [Nexus](https://nexus.k8s.praktikum-services.tech/repository/eremenko-grigorii-dumplings-store-helm/)
- анализ кода:
[SonarQube_Frontend](https://sonarqube.praktikum-services.ru/dashboard?id=14_GRIGORIIEREMENKO__DUMPLINGS_FRONTEND)
[SonarQube_Backend](https://sonarqube.praktikum-services.ru/dashboard?id=14_GRIGORIIEREMENKO__DUMPLINGS_BACKEND)
- docker-images ---> [Gitlab Container Registry](https://gitlab.praktikum-services.ru/std-014-19/nk-dumplings/container_registry)
- Статические объекты хранятся в Yandex S3 ---> [nk-dumpling-bucket/nk-pics](https://cloud.yandex.ru/services/storage/)
- Состояние terraform хранится в Yandex S3 ---> [nk-dumpling-bucket](https://cloud.yandex.ru/services/storage/)
- Managed K8S ---> [Yandex Managed Service for Kubernetes](https://cloud.yandex.ru/services/managed-kubernetes)

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

## [Monitoring](https://grafana.nk-dumplings.ru/)

Креды:
#Креды по умолчанию хранятся в секрете {{ .ReleaseName }}-grafana
#Значения по умолчанию можно изменить передав ключи при установке helm-chart'a
admin | prom-operator

- [frontend](https://grafana.nk-dumplings.ru/d/9bSijBjVz/1_nginx-frontend?orgId=1)

<img width="500" alt="image" src="https://storage.yandexcloud.net/nk-dumpling-bucket/monitoring/frontend.png">

- [backend](https://grafana.nk-dumplings.ru/d/wqSuCfjVz/1_nginx-backend?orgId=1)

<img width="500" alt="image" src="https://storage.yandexcloud.net/nk-dumpling-bucket/monitoring/backend.png">

- [logs](https://grafana.nk-dumplings.ru/d/sadlil-loki-apps-dashboard/logs-app?orgId=1&var-app=nk%2Fnk-backend&var-search=)

<img width="500" alt="image" src="https://storage.yandexcloud.net/nk-dumpling-bucket/monitoring/promtail.png">

- [infrastructure](https://grafana.nk-dumplings.ru/d/garysdevil-kube-state-metrics-v2/kube-state-metrics-v2?orgId=1)

<img width="500" alt="image" src="https://storage.yandexcloud.net/nk-dumpling-bucket/monitoring/kube-state.png">

- [go_metrics](https://grafana.nk-dumplings.ru/d/CgCw8jKZz/go-metrics?orgId=1&refresh=5s)
<img width="500" alt="image" src="https://storage.yandexcloud.net/nk-dumpling-bucket/monitoring/go-metrics.png">


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
|  В GitLab CI описан шаг деплоя |  Выполнено | Поддерживается деплой на тестовую ВМ, но её "как-бы" нет. В проде деплоим сразу в k8s
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
