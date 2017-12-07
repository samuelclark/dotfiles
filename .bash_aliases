starthadoop() {
  ./start.sh -n -Y -d predapi -d pngexport
}
 
startetl() {
  ./start.sh -n -Y -E -j -d predapi -d pngexport
}
 
cdhadooplogs() {
  docker exec -it localdevhadoop_master_1 /bin/bash -c "cd /usr/local/hadoop/logs/; exec ${SHELL:-sh}"
}

 
cptohdfs() {
  #copies local file from native/vagrant environment into local-dev-hadoop hdfs
  local_hadoop_docker_container=$(docker ps | grep 'local-hadoop' | grep master | grep -Eo '^[^ ]+')
 
  echo "Copying $1 into local Hadoop docker container ($local_hadoop_docker_container), then into HDFS at path $2"
  docker exec -it $local_hadoop_docker_container /bin/bash -c "cd /opt/workspace/data; hadoop dfs -put $1 $2"
 
  if [ $? -eq 0 ]; then
      echo "Copying Successful"
  else
      echo "Copying Failed"
  fi
}
 
cddatarobot() {
  cd $PROJECT_HOME/DataRobot
  workon dev
}

alias ds='cd /home/ubuntu/workspace/datasets-service'
alias dr='cd /home/ubuntu/workspace/DataRobot'
alias ldh='cd /home/ubuntu/workspace/local-dev-hadoop'
alias rmcontainers='docker rm -v $(docker ps -a -q -f status=exited)'
alias killcontainers='docker kill $(docker ps -q)'
alias dlf='docker logs -f $@'
alias chlogs='sudo rm -rf /home/ubuntu/workspace/datasets-service/.logs/master'
alias tmongo='docker exec -it $(docker ps -aqf name=datasetsservice_testmongo_1) mongo admin -u admin -p password'

ccontainers(){
  killcontainers
  rmcontainers
}
startapp() {
  cddatarobot
 
  unset ETL_SAMPLE_SIZE
  unset ENABLE_WORKERS_ON_YARN
  unset ENABLE_HADOOP_DEPLOYMENT
  unset ENABLE_DATASETS_SERVICE_ETL
 
  if [ ! -z "$1" ]; then
    while true; do
      case "$1" in
        'hdfs')
          export ENABLE_WORKERS_ON_YARN="True"
          export ENABLE_HADOOP_DEPLOYMENT="True"
          starthadoop
          cptohdfs ~/workspace/datasets/10k_diabetes.csv /tmp/datasets/10k.csv
          break;;
        'etl')
          export ETL_SAMPLE_SIZE=136870912
          export ENABLE_WORKERS_ON_YARN="True"
          export ENABLE_HADOOP_DEPLOYMENT="True"
          export ENABLE_DATASETS_SERVICE_ETL="True"
          startetl
 #         cptohdfs ~/workspace/datasets/10k_diabetes.csv /tmp/datasets/10k.csv
 #         cptohdfs ~/workspace/datasets/Liberty-Mutal-training.csv /tmp/big/Liberty-Mutal-training.csv
          break;;
        'predapp')
          ./start.sh --pred-app
          break;;
        esac
    done
  else
    ./start.sh
  fi
}
 
 
stopapp() {
  cddatarobot
  if [ "$1" == "all" ]; then
    ./stop.sh --full
  else
    ./stop.sh
  fi
}

