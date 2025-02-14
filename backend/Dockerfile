FROM python:3.11.5
WORKDIR /backend
COPY . .
COPY wait-for-kafka.sh /wait-for-kafka.sh
RUN pip install -r requirements.txt
EXPOSE 5000
RUN chmod +x /wait-for-kafka.sh
CMD ["/wait-for-kafka.sh"]


