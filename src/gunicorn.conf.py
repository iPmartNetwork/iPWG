import multiprocessing
import dashboard
import logging

logging.basicConfig(level=logging.ERROR)  # Configure logging for error messages

try:
    app_host, app_port = dashboard.get_host_bind()
except Exception as e:
    if "No section: 'Server'" in str(e):
        logging.error("Configuration error: Missing 'Server' section in the configuration file.")
    else:
        logging.error(f"Unexpected error fetching host bind: {e}")
    app_host, app_port = "127.0.0.1", 8000  # Default values

worker_class = 'gthread'
workers = multiprocessing.cpu_count() * 2 + 1
threads = 4
bind = f"{app_host}:{app_port}"
daemon = True
pidfile = './gunicorn.pid'