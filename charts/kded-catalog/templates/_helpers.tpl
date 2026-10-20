{{- define "kded-catalog.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "kded-catalog.browserProbe" -}}
exec:
  command:
    - python3
    - -c
    - |
      import http.client, os, socket
      with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as display:
          display.settimeout(1)
          display.connect("/tmp/.X11-unix/X" + os.environ["DISPLAY_NUM"])
      with socket.create_connection(("127.0.0.1", 5900), timeout=1) as vnc:
          with vnc.makefile("rb") as greeting:
              if not greeting.read(12).startswith(b"RFB "):
                  raise SystemExit("VNC greeting unavailable")
      for port, path in ((4444, "/status"), (7900, "/vnc.html")):
          connection = http.client.HTTPConnection("127.0.0.1", port, timeout=1)
          try:
              connection.request("GET", path)
              if connection.getresponse().status != 200:
                  raise SystemExit("Desktop service unavailable")
          finally:
              connection.close()
timeoutSeconds: 5
{{- end -}}
{{- define "kded-catalog.labels" -}}
app.kubernetes.io/name: kded-catalog
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
