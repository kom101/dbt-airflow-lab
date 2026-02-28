FROM astrocrpublic.azurecr.io/astronomer/astro-runtime:13.4.0

USER root

# Instalujemy wszystko do głównego środowiska, aby uniknąć konfliktów w venv
RUN pip install --no-cache-dir --index-url http://host.docker.internal:3141/root/pypi/+simple/ --trusted-host host.docker.internal \
    dbt-postgres==1.8.2 \
    dbt-bigquery==1.8.2 \
    astronomer-cosmos==1.8.2 \
    openlineage-dbt==1.28.0

# Tworzymy katalogi na dbt i nadajemy uprawnienia (całkowicie poza dbt_project)
RUN mkdir -p /tmp/dbt_packages /tmp/dbt_target && \
    chown -R astro: /tmp/dbt_packages /tmp/dbt_target

USER astro
