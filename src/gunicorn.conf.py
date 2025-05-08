import multiprocessing
import dashboard

try:
    app_host, app_port = dashboard.get_host_bind()
except Exception as e:
    print(f"Error fetching host bind: {e}")
    app_host, app_port = "127.0.0.1", 8000  # Default values

worker_class = 'gthread'
workers = multiprocessing.cpu_count() * 2 + 1
threads = 4
bind = f"{app_host}:{app_port}"
daemon = True
pidfile = './gunicorn.pid'
