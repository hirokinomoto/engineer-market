# Python前処理用の最小Docker環境
# e-Stat ExcelをBigQuery投入用CSVへ変換するために使用する

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY python/ ./python/

CMD ["python", "python/extract_estat_job_market.py"]
