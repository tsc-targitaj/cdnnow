# cdnnow
Тестовое задание.

<h2>Дано</h2>
Требуется написать скрипты деплоя на окружение dev и prod в Kubernetes приложения.<br>
Результат выполнения задачи должен быть передан в виде ссылки на github.com или любого другого публичного git репозитория.<br>
Требования к приложению:<br>
1.  Приложение состоит из nginx, php-fpm и единственной страницы index.php:<br>
```
<? php
echo "Hello world!";
```<br>
2.  Файл index.php должен быть в контейнере (т.е. не должен быть подключен из вне)<br>
3.  В качестве платформы для запуска Kubernetes рекомендуется использовать minikube<br>
4.  Страница должна открываться по адресу “/” (т.е. не “/index.php”)<br>
5.  Вы можете выбрать инструменты для организации деплоя на ваше усмотрение<br>
