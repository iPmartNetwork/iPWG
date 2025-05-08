import multiprocessing
import sys  # Add sys for exiting the script

try:
    import dashboard
except ModuleNotFoundError as e:
    if "flask_limiter" in str(e):
        raise ImportError("The 'flask_limiter' module is missing. Install it using 'pip install flask-limiter'.") from e
        sys.exit(1)  # Ensure the script exits after raising the error
    raise

app_host, app_port = dashboard.get_host_bind()

worker_class = 'gthread'
workers = multiprocessing.cpu_count() * 2 + 1
threads = 4
bind = f"{app_host}:{app_port}"
daemon = True
pidfile = './gunicorn.pid'
