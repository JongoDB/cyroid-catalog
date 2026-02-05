#!/usr/bin/env python3
"""
CYROID Red Team Lab - Vulnerable CI/CD Dashboard
Intentionally vulnerable for security training purposes.

Vulnerabilities:
- Command injection in build script execution
- Weak authentication
- No CSRF protection
"""

from flask import Flask, request, render_template, redirect, session, flash
import subprocess
import os

app = Flask(__name__)
app.secret_key = 'insecure-secret-key-12345'  # Intentionally weak

# Hardcoded users (intentionally insecure)
USERS = {
    'admin': 'admin',
    'developer': 'Dev2024!'
}

# Sample jobs
JOBS = [
    {'name': 'deploy-webapp', 'status': 'success', 'last_run': '2024-01-15 10:30'},
    {'name': 'backup-database', 'status': 'success', 'last_run': '2024-01-15 02:00'},
    {'name': 'security-scan', 'status': 'failed', 'last_run': '2024-01-14 23:00'},
]

@app.route('/')
def index():
    if 'user' not in session:
        return redirect('/login')
    return render_template('index.html', user=session['user'], jobs=JOBS)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username', '')
        password = request.form.get('password', '')
        if username in USERS and USERS[username] == password:
            session['user'] = username
            return redirect('/')
        flash('Invalid credentials')
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect('/login')

@app.route('/script-console', methods=['GET', 'POST'])
def script_console():
    """
    VULNERABLE: Command injection via script execution
    This simulates Jenkins' Groovy script console
    """
    if 'user' not in session:
        return redirect('/login')

    output = ''
    if request.method == 'POST':
        script = request.form.get('script', '')
        if script:
            try:
                # VULNERABLE: Direct command execution
                result = subprocess.run(
                    script,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                output = result.stdout + result.stderr
            except subprocess.TimeoutExpired:
                output = 'Script execution timed out'
            except Exception as e:
                output = f'Error: {str(e)}'

    return render_template('script_console.html', user=session['user'], output=output)

@app.route('/build/<job_name>', methods=['POST'])
def trigger_build(job_name):
    """Trigger a build job"""
    if 'user' not in session:
        return redirect('/login')
    flash(f'Build triggered for {job_name}')
    return redirect('/')

@app.route('/configure/<job_name>', methods=['GET', 'POST'])
def configure_job(job_name):
    """
    VULNERABLE: Command injection in build commands
    """
    if 'user' not in session:
        return redirect('/login')

    output = ''
    if request.method == 'POST':
        build_cmd = request.form.get('build_command', '')
        if build_cmd:
            try:
                # VULNERABLE: Direct command execution
                result = subprocess.run(
                    build_cmd,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                output = f"Build output:\n{result.stdout}{result.stderr}"
            except Exception as e:
                output = f'Error: {str(e)}'

    return render_template('configure.html',
                         user=session['user'],
                         job_name=job_name,
                         output=output)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
