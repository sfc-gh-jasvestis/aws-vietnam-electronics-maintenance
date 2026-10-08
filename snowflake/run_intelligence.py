"""Run 05_ml.sql and/or 06_intelligence.sql against an isolated pilot database.

Only validated identifiers and an email address are substituted into the SQL.
Usage: python snowflake/run_intelligence.py --database REPAIR_..._C --alert-email you@example.com [--files 06_intelligence.sql]
"""
import argparse
import io
import re
import sys
from pathlib import Path

from run_core import connect, validate_target

HERE = Path(__file__).resolve().parent


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--connection', default='demo43')
    ap.add_argument('--database', required=True)
    ap.add_argument('--warehouse', default='HOL_GEN2_WH')
    ap.add_argument('--alert-email', required=True)
    ap.add_argument('--files', nargs='+', default=['05_ml.sql', '06_intelligence.sql'])
    args = ap.parse_args()
    validate_target(args.database, args.warehouse)
    if not re.fullmatch(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', args.alert_email):
        raise ValueError('invalid email')
    from snowflake.connector.util_text import split_statements
    con = connect(args.connection)
    cur = con.cursor()
    cur.execute('SELECT CURRENT_ACCOUNT()')
    if cur.fetchone()[0] != 'YFB94191':
        raise RuntimeError('Snowflake identity mismatch')
    cur.execute('SET DEMO_DB = %s', (args.database,))
    cur.execute('SET DEMO_WH = %s', (args.warehouse,))
    cur.execute(f'USE DATABASE {args.database}')
    cur.execute(f'USE WAREHOUSE {args.warehouse}')
    try:
        for name in args.files:
            sql = (HERE / name).read_text()
            sql = (sql.replace('__DEMO_DB__', args.database).replace('__DEMO_WH__', args.warehouse)
                      .replace('__ALERT_EMAIL__', args.alert_email))
            for statement, _ in split_statements(io.StringIO(sql)):
                if statement.strip():
                    cur.execute(statement)
                    first = [l for l in statement.strip().splitlines() if not l.startswith('--')]
                    print('ok', name, cur.sfqid, (first[0] if first else '')[:80])
    finally:
        try:
            cur.execute(f'ALTER WAREHOUSE {args.warehouse} SUSPEND')
        except Exception:
            pass  # already suspended


if __name__ == '__main__':
    sys.exit(main())
