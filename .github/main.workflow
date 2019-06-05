workflow "Build and publish to DockerHub" {
  on = "push"
  resolves = ["Deploy", "Publish"]
}

action "Docker Registry" {
  uses = "actions/docker/login@master"
  secrets = ["DOCKER_USERNAME", "DOCKER_PASSWORD"]
}

action "Build" {
  needs = ["Docker Registry"]
  uses = "docker://simonvadee/action-docker-service:latest"
  runs = "make"
  args = "build"
}

action "Filter" {
  needs = ["Build"]
  uses = "actions/bin/filter@master"
  args = "branch master"
}

action "Publish" {
  needs = ["Filter"]
  uses = "docker://simonvadee/action-docker-service:latest"
  runs = "make"
  args = "publish"
}

action "Deploy" {
  uses = "actions/bin/sh@master"
  secrets = ["DEPLOYMENT_KEY", "DEPLOYMENT_USER", "DEPLOYMENT_HOST"]
  args = [
    "echo $DEPLOYMENT_KEY > id_rsa",
    "scp -i id_rsa ./docker-compose.yml $DEPLOYMENT_USER@$DEPLOYMENT_HOST:/home/$DEPLOYMENT_USER/stack.yml",
    "ssh -i id_rsa $DEPLOYMENT_USER@$DEPLOYMENT_HOST 'docker stack deploy -c stack.yml '"
  ]
}
