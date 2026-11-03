from django.contrib import admin
from django.urls import path

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

# Registrar as rotas no Router
router = DefaultRouter()
router.register(r'actors', ActorViewSet, basename='actor')
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'films', FilmViewSet, basename='film')
router.register(r'customers', CustomerViewSet, basename='customer')
router.register(r'rentals', RentalViewSet, basename='rental')
router.register(r'payments', PaymentViewSet, basename='payment')
urlpatterns = [
    path("admin/", admin.site.urls),

    # Rotas do DRF
    path('api/', include(router.urls)),
    
    # 2. Rotas do drf-spectacular
    # Esquema OpenAPI em formato JSON/YAML (/api/schema/)
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    
    # Interface Swagger UI (/api/schema/swagger-ui/)
    path(
        'api/docs/',
        SpectacularSwaggerView.as_view(url_name='schema'),
        name='swagger-ui',
    ),
    
    # Interface ReDoc (/api/schema/redoc/)
    path(
        'api/schema/redoc/',
        SpectacularRedocView.as_view(url_name='schema'),
        name='redoc',
    ),
]