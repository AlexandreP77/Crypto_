FROM python:3.11.5
WORKDIR /backend-nifi
COPY . .
RUN pip install -r requirements.txt
EXPOSE 9859
CMD ["python", "app.py"]
