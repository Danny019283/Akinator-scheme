import os
import sys

_PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
for _sub in ("comunicacion", "servicios"):
    sys.path.insert(0, os.path.join(_PROJECT_ROOT, _sub))
