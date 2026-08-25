## geral

- siga as convenções e boas práticas do Django
- use features do Django 4.x+ quando apropriado
- siga o PEP 8 como guia de estilo para código Python
- use os recursos nativos do Django antes de criar soluções customizadas
- sempre use o Django ORM ao invés de SQL raw quando possível

## estrutura

- organize o código em apps Django com responsabilidades claras
- mantenha apps focados e reutilizáveis quando possível
- use `models.py`, `views.py`, `urls.py`, `serializers.py` apropriadamente
- separe a lógica de negócio em services ou managers
- use a estrutura de settings do Django (base, local, production)
- mantenha templates organizados por app ou feature

## boas práticas

- use class-based views (CBVs) para views complexas, function-based views para simples
- use Django Rest Framework para desenvolvimento de APIs
- use Django signals com moderação, prefira chamadas explícitas
- sempre valide e sanitize input do usuário
- use `get_object_or_404` ao invés de try/except para queries de model
- use `select_related` e `prefetch_related` para otimizar queries
- evite N+1 queries usando os métodos corretos do ORM
- use Django migrations para todas as mudanças no banco de dados

## segurança

- sempre valide permissões do usuário com decorators ou mixins
- use a autenticação e autorização nativa do Django
- proteja contra CSRF, XSS e SQL injection
- use variáveis de ambiente para configurações sensíveis
- nunca faça commit de `SECRET_KEY` ou credenciais no controle de versão
