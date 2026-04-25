{{/* Generate a stable port based on the server name */}}
{{- define "game.port" -}}
  {{- $name := . -}}
  {{- /* Hash the name, take the first 7 chars of the hex, convert to decimal */}}
  {{- $hash := adler32sum $name | printf "%s" -}}
  {{- /* Convert hash to an integer and mod it to a range of 485 ports */}}
  {{- $offset := mod (atoi $hash) 485 -}}
  {{- add 27015 $offset -}}
{{- end -}}