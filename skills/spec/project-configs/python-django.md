# .devloop/domain.md example - Python / Django

Example configuration for a Django web application with
Django REST Framework.

---

## Domain Context

Django web application serving browser users and API consumers.
Admin interface for internal data management. PostgreSQL database
with Django ORM.

---

## Architecture Overview

URLs -> Views (or ViewSets) -> Services/Managers -> Models -> PostgreSQL

- Views handle HTTP and serialization (DRF serializers)
- Services contain business logic (no HTTP awareness)
- Models define schema and simple domain methods
- Celery for background tasks
- Django admin for internal data management

---

## Domain-Specific Concerns (Validation Checklist §9)

- [ ] N+1 queries: select_related/prefetch_related for related objects
- [ ] Timezone-aware datetimes: USE_TZ=True, no naive datetimes
- [ ] Migration safety: backward-compatible migrations for zero-downtime
- [ ] File upload limits: max size, allowed types, storage backend
- [ ] CSRF protection: forms and API endpoints handle tokens correctly
- [ ] Admin interface: data management features include admin actions
- [ ] Signals: avoid implicit coupling via Django signals

---

## Existing Patterns

- Class-based views with DRF ViewSets for API endpoints
- Pydantic or DRF serializers for input validation
- Protocol classes for service interfaces (not ABC)
- Django managers for complex queries (not raw SQL)
- Celery tasks for async operations (email, reports, sync)
- pytest with factory_boy for test data

---

## Quality Standards

- [ ] Database-touching stories include migration considerations
- [ ] Admin interface stories for data management features
- [ ] Background task stories specify retry and failure behavior
- [ ] API stories include serialization format criteria
- [ ] Features with user input specify validation rules
- [ ] Query-heavy features note expected query count
