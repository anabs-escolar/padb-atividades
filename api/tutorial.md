# Tutorial: Criando uma API Django REST a partir de um Banco de Dados PostgreSQL Existente (`dvdrental`)

Este tutorial guia o processo de criação de uma API REST em Django integrando um banco de dados PostgreSQL preexistente, ajustando os modelos automáticos gerados pelo `inspectdb` e configurando a documentação Swagger interativa com o `drf-spectacular`.

---

## Passo 1: Preparação do Ambiente e Projeto Django

1. **Crie a pasta do projeto e acesse o diretório:**
```bash
mkdir api
cd api

```


2. **Instale os pacotes necessários:**
```bash
pip install django djangorestframework drf-spectacular "psycopg[binary]"

```


3. **Salve as dependências no arquivo `requirements.txt`:**
```bash
pip freeze > requirements.txt

```


4. **Crie a estrutura inicial do projeto e da aplicação:**
```bash
django-admin startproject config
mv config dvdrental
cd dvdrental
python manage.py startapp backend

```



---

## Passo 2: Configuração do `settings.py`

Abra o arquivo `dvdrental/settings.py` e realize as configurações abaixo.

1. **Adicione as aplicações no `INSTALLED_APPS`:**
```python
INSTALLED_APPS = [
    # Aplicações padrão do Django...
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Libs de terceiros
    'rest_framework',
    'drf_spectacular',

    # App da sua API
    'backend',
]

```


2. **Configure a conexão com o banco de dados PostgreSQL:**
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'dvdrental',
        'USER': 'postgres',
        'PASSWORD': 'postgres',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

```


3. **Adicione a configuração do `drf-spectacular` ao final do arquivo:**
```python
REST_FRAMEWORK = {
    'DEFAULT_SCHEMA_CLASS': 'drf_spectacular.openapi.AutoSchema',
}

```



---

## Passo 3: Testando a Conexão com o PostgreSQL

1. **Inicie o serviço do PostgreSQL (caso esteja desligado):**
```bash
sudo service postgresql start

```


2. **Valide a conexão via terminal interativo do Django:**
```bash
python manage.py shell

```


*No terminal do Python:*
```python
from django.db import connection
with connection.cursor() as cursor:
    cursor.execute("SELECT current_database(), current_user, version();")
    print(cursor.fetchone())
exit()

```



---

## Passo 4: Mapeamento do Banco de Dados (`inspectdb`)

Gere os modelos automaticamente a partir das tabelas existentes no banco de dados e salve-os em `backend/models.py`:

```bash
python manage.py inspectdb > backend/models.py

```

---

## Passo 5: Correção de Erros nos Modelos Gerados

Abra o arquivo `backend/models.py` para corrigir incompatibilidades comuns geradas pelo `inspectdb`:

### 1. Correção no Modelo `People` (Múltiplos Campos Auto-Incremento)

* **Erro:** `ValueError: Model backend.People can't have more than one auto-generated field.`
* **Solução:** Altere `person_code` para `models.IntegerField()`.

```python
class People(models.Model):
    id = models.BigAutoField(primary_key=True)
    person_code = models.IntegerField()  # Alterado de AutoField para IntegerField
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)

    class Meta:
        managed = False
        db_table = 'people'

```

### 2. Correção no Modelo `Payment` (`on_delete=SET_NULL` sem Nulo)

* **Erro:** `backend.Payment.rental: (fields.E320) Field specifies on_delete=DB_SET_NULL, but cannot be null.`
* **Solução:** Adicione `null=True` e `blank=True` na ForeignKey `rental`.

```python
class Payment(models.Model):
    payment_id = models.AutoField(primary_key=True)
    customer = models.ForeignKey(Customer, models.DO_NOTHING)
    staff = models.ForeignKey('Staff', models.DO_NOTHING)
    rental = models.ForeignKey(
        'Rental',
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    amount = models.DecimalField(max_digits=5, decimal_places=2)
    payment_date = models.DateTimeField()

    class Meta:
        managed = False
        db_table = 'payment'

```

### 3. Aplicação e Validação das Alterações

Execute os comandos abaixo para sincronizar o projeto Django:

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py check

```

---

## Passo 6: Criação dos Serializers, ViewSets e Rotas

### 1. Crie o arquivo `backend/serializers.py`

```python
from rest_framework import serializers
from .models import Actor, Film, Category, Customer, Rental, Payment

class ActorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Actor
        fields = '__all__'

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = '__all__'

class FilmSerializer(serializers.ModelSerializer):
    class Meta:
        model = Film
        fields = '__all__'

class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Customer
        fields = '__all__'

class RentalSerializer(serializers.ModelSerializer):
    class Meta:
        model = Rental
        fields = '__all__'

class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'

```

### 2. Atualize o arquivo `backend/views.py`

```python
from rest_framework import viewsets
from .models import Actor, Film, Category, Customer, Rental, Payment
from .serializers import (
    ActorSerializer,
    FilmSerializer,
    CategorySerializer,
    CustomerSerializer,
    RentalSerializer,
    PaymentSerializer,
)

class ActorViewSet(viewsets.ModelViewSet):
    queryset = Actor.objects.all()
    serializer_class = ActorSerializer

class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class FilmViewSet(viewsets.ModelViewSet):
    queryset = Film.objects.all()
    serializer_class = FilmSerializer

class CustomerViewSet(viewsets.ModelViewSet):
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer

class RentalViewSet(viewsets.ModelViewSet):
    queryset = Rental.objects.all()
    serializer_class = RentalSerializer

class PaymentViewSet(viewsets.ModelViewSet):
    queryset = Payment.objects.all()
    serializer_class = PaymentSerializer

```

### 3. Configure as URLs em `dvdrental/urls.py`

```python
from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from drf_spectacular.views import (
    SpectacularAPIView,
    SpectacularRedocView,
    SpectacularSwaggerView,
)

from backend.views import (
    ActorViewSet,
    CategoryViewSet,
    FilmViewSet,
    CustomerViewSet,
    RentalViewSet,
    PaymentViewSet,
)

# Configuração do Router da API
router = DefaultRouter()
router.register(r'actors', ActorViewSet, basename='actor')
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'films', FilmViewSet, basename='film')
router.register(r'customers', CustomerViewSet, basename='customer')
router.register(r'rentals', RentalViewSet, basename='rental')
router.register(r'payments', PaymentViewSet, basename='payment')

urlpatterns = [
    path('admin/', admin.site.urls),

    # Endpoints da API REST
    path('api/', include(router.urls)),

    # Documentação Swagger e OpenAPI
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/schema/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),
]

```

---

## Passo 7: Execução e Testes

1. **Inicie o servidor de desenvolvimento:**
```bash
python manage.py runserver

```


2. **Acesse as URLs principais no seu navegador:**
* **Swagger UI (Documentação Interativa):** `[http://127.0.0.1:8000/api/docs/](http://127.0.0.1:8000/api/docs/)`
* **ReDoc (Documentação Alternativa):** `[http://127.0.0.1:8000/api/schema/redoc/](http://127.0.0.1:8000/api/schema/redoc/)`
* **Navegador de Endpoints da API:** `[http://127.0.0.1:8000/api/](http://127.0.0.1:8000/api/)`