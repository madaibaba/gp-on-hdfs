## gpdb on HDFS Docker Containers


![alt tag](https://raw.githubusercontent.com/madaibaba/gp-on-hdfs/master/gp-on-hdfs.png)


#### 1. Clone Github Repository

```
git clone https://github.com/madaibaba/gp-on-hdfs
```

#### 2. Pull Docker Image

```
sudo docker pull madaibaba/gp-on-hdfs:2.0
```

#### 3. Create My Bridge Network

```
sudo docker network create -d bridge mybridge
```

#### 4. Start Docker Container

##### 4.1 Start Three Container for default (one master and two slaves)

```
cd gp-on-hdfs
sudo ./start-container.sh
```

##### 4.2 Start Three Container as below (one master and five slaves)

```
cd gp-on-hdfs
sudo ./start-container.sh 3
```
