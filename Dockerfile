FROM python:3.7.5-slim
LABEL author="myname@example.com"
RUN pip install flask==2.2.3
COPY ./server.py /server.py
ENV PORT=80
CMD ["python", "-u", "/server.py"]