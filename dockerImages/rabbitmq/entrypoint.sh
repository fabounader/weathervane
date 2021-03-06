#!/bin/bash

sigterm()
{
   echo "signal TERM received. pid = $pid"
   rm -f /fifo
   kill -TERM $pid
   exit 0
}

sigusr1()
{
   echo "signal USR1 received.  pid = $pid. We don't reload RabbitMQ"
}

trap 'sigterm' TERM
trap 'sigusr1' USR1

echo "Add weathervane domain to resolv.conf" 
perl /updateResolveConf.pl

echo "Set file permissions" 
chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
chmod 600 /var/lib/rabbitmq/.erlang.cookie
chmod 600 /root/.erlang.cookie

hostname="$(hostname)"
echo "NODENAME=rabbit@${hostname}" > /etc/rabbitmq/rabbitmq-env.conf

if [ $# -gt 0 ]; then
	eval "$* &"
else
    echo "Start RabbitMQ: setsid sudo -u rabbitmq RABBITMQ_NODE_PORT=${RABBITMQ_NODE_PORT} RABBITMQ_DIST_PORT=${RABBITMQ_DIST_PORT} rabbitmq-server &"
	setsid sudo -u rabbitmq RABBITMQ_NODE_PORT=${RABBITMQ_NODE_PORT} RABBITMQ_DIST_PORT=${RABBITMQ_DIST_PORT} rabbitmq-server &
fi

pid="$!"


if [ ! -e "/fifo" ]; then
	mkfifo /fifo || exit
fi
chmod 400 /fifo

# wait indefinitely
while true;
do
  echo "Waiting for child to exit."
  read < /fifo
  echo "Child Exited"
done
