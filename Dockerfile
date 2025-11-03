# Dockerfile para API de Geração de Boletos
FROM python:3.9-slim

# Definir diretório de trabalho
WORKDIR /app

# Instalar dependências do sistema necessárias para ReportLab e Pillow
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar arquivo de requirements
COPY requirements_api.txt .

# Instalar dependências Python
RUN pip install --no-cache-dir -r requirements_api.txt

# Copiar código da aplicação
COPY api_boleto.py .
COPY pyboleto/ ./pyboleto/

# Criar diretório para logs
RUN mkdir -p /app/logs

# Expor porta
EXPOSE 5000

# Variáveis de ambiente
ENV FLASK_APP=api_boleto.py
ENV PYTHONUNBUFFERED=1

# Comando para executar a aplicação com Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "--timeout", "120", "--access-logfile", "/app/logs/access.log", "--error-logfile", "/app/logs/error.log", "api_boleto:app"]
