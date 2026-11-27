"""Локальный прогон всех задач DAG через API Airflow dag.test()."""
import argparse
from datetime import date
from pathlib import Path

import pendulum
from airflow.models import DagBag
from airflow.utils.state import DagRunState

ROOT = Path(__file__).resolve().parents[1]


def run(day):
    bag = DagBag(dag_folder=str(ROOT / "dags"), include_examples=False)
    if bag.import_errors:
        raise RuntimeError(bag.import_errors)
    dag = bag.get_dag("horizon_elt")
    if dag is None:
        raise RuntimeError("horizon_elt не найден")
    for task in dag.tasks:
        task.retries = 0
    result = dag.test(execution_date=pendulum.now("UTC"), run_conf={"batch_date": day})
    if result.state != DagRunState.SUCCESS:
        raise SystemExit(f"{day}: {result.state}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("dates", nargs="+")
    for raw in parser.parse_args().dates:
        run(date.fromisoformat(raw).isoformat())
