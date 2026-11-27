"""Создаёт демонстрационный дашборд через Metabase API (проверено на 0.54.10)."""
import json
import os
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
URL = os.environ.get("METABASE_URL", "http://127.0.0.1:3000").rstrip("/")


def api(method, path, body=None, session=None):
    data = None if body is None else json.dumps(body).encode()
    headers = {"Content-Type": "application/json"}
    if session:
        headers["X-Metabase-Session"] = session
    try:
        with urlopen(Request(URL + "/api/" + path, data, headers, method=method), timeout=60) as res:
            return json.load(res)
    except HTTPError as error:
        raise RuntimeError(f"{method} {path}: {error.code} {error.read().decode()}") from error


def create():
    email = os.environ["METABASE_EMAIL"]
    password = os.environ["METABASE_PASSWORD"]
    db_details = {
        "host": os.environ.get("DWH_HOST", "127.0.0.1"),
        "port": int(os.environ.get("DWH_PORT", "5432")),
        "dbname": os.environ.get("DWH_DB", "horizon"),
        "user": "horizon_bi",
        "password": os.environ["HORIZON_BI_PASSWORD"],
        "ssl": False,
        "schema-filters-type": "inclusion",
        "schema-filters-patterns": "marts",
    }
    database = {"engine": "postgres", "name": "Горизонт DWH", "details": db_details}
    token = api("GET", "session/properties").get("setup-token")
    if token:
        api("POST", "setup", {
            "token": token,
            "user": {"first_name": "Учебный", "last_name": "Администратор",
                     "email": email, "password": password},
            "prefs": {"site_name": "Горизонт", "allow_tracking": False},
        })
    session = api("POST", "session", {"username": email, "password": password})["id"]
    databases = api("GET", "database", session=session)["data"]
    found = next((item for item in databases if item["name"] == database["name"]), None)
    db_id = (found or api("POST", "database", database, session))["id"]
    specs = [
        ("Динамика продаж по дням", "line", "sales_by_day.sql", "Дата"),
        ("Топ-10 товаров по выручке", "bar", "top_products.sql", "Товар (SKU)"),
    ]
    dashboard = api("POST", "dashboard", {
        "name": "Горизонт — продажи",
        "description": "Учебные данные. Витрина marts.fct_sales_daily. Суммы в рублях.",
    }, session)
    cards = []
    for index, (name, display, file, dimension) in enumerate(specs, start=1):
        card = api("POST", "card", {
            "name": name, "display": display, "description": "Источник: marts.fct_sales_daily",
            "dataset_query": {"type": "native", "database": db_id,
                              "native": {"query": (ROOT / file).read_text(encoding="utf-8")}},
            "visualization_settings": {"graph.dimensions": [dimension],
                                       "graph.metrics": ["Выручка, ₽"],
                                       "graph.show_values": display == "bar"},
        }, session)
        result = api("POST", f"card/{card['id']}/query", {}, session)
        row_count = result.get("row_count", len(result.get("data", {}).get("rows", [])))
        if result.get("status") != "completed" or row_count == 0:
            raise RuntimeError(f"Запрос карточки не вернул данные: {name}")
        print(f"{name}: {row_count} строк")
        cards.append({"id": -index, "card_id": card["id"], "row": 0,
                      "col": (index - 1) * 12, "size_x": 12, "size_y": 9,
                      "parameter_mappings": [], "visualization_settings": {}})
    dash_id = dashboard["id"]
    api("PUT", f"dashboard/{dash_id}", {"dashcards": cards}, session)
    saved = api("GET", f"dashboard/{dash_id}", session=session)
    if len(saved.get("dashcards", [])) != len(specs):
        raise RuntimeError("Не все карточки появились на дашборде")
    print(f"{URL}/dashboard/{dash_id}")


if __name__ == "__main__":
    create()
