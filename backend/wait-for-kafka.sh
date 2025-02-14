#!/bin/sh
echo "Attente de Kafka..."
wget http://sourceforge.net/projects/netcat/files/netcat/0.7.1/netcat-0.7.1.tar.gz
tar -xzvf netcat-0.7.1.tar.gz
cd netcat-0.7.1
./configure
make
make install
cd /backend
while ! nc -z kafka 9092; do
  sleep 1
done
echo "Kafka est prêt, démarrage de l'application."
exec python app.py
