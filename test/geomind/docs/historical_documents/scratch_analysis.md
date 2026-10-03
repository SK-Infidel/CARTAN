

# scratch\check_checkpoint.py
`python
import torch
import sys
import os

sys.path.append(os.path.abspath("."))
import config
from core.agent_core import AgentCore

print(f"Current config.NUM_DECOMP_STREAMS = {config.NUM_DECOMP_STREAMS}")
print(f"Current config.USE_BCEN = {config.USE_BCEN}")

device = "cpu"
agent = AgentCore().to(device)

path = "checkpoints/e8_agent_model.pt"
if not os.path.exists(path):
    print(f"Checkpoint {path} does not exist!")
    sys.exit(1)

print(f"Loading {path}...")

`

# scratch\check_dataset_stats.py
`python
import numpy as np

def check_dataset():
    coords_path = 'trainingdata/datasets/ohsuz_tiny-textbooks-merged_train_e8_coords.npy'
    ic_path = 'trainingdata/datasets/ohsuz_tiny-textbooks-merged_train_ic.npy'
    
    print("Loading coords...")
    coords = np.load(coords_path, mmap_mode='r')
    print("Coords shape:", coords.shape)
    print("Coords dtype:", coords.dtype)
    print("Coords mean:", np.mean(coords[:10000]))
    print("Coords std:", np.std(coords[:10000]))
    print("Coords min:", np.min(coords[:10000]))
    print("Coords max:", np.max(coords[:10000]))
    print("Coords has NaN:", np.isnan(coords[:10000]).any())
    
    try:
        print("\nLoading ICs...")
        ics = np.load(ic_path, mmap_mode='r')
        print("ICs shape:", ics.shape)

`

# scratch\check_db.py
`python
import sqlite3
import numpy as np
from scipy.spatial import cKDTree
import torch
from core.bcen import ByteCoordinateEncoder
from core.blt_tokenizer import BLTTokenizer

bcen = ByteCoordinateEncoder()
tokenizer = BLTTokenizer()

conn = sqlite3.connect("checkpoints/geometry_registry.db")
cursor = conn.cursor()
cursor.execute("SELECT text_lemma, coordinate_blob FROM geometry_registry WHERE coordinate_blob IS NOT NULL")
rows = cursor.fetchall()
strings = []
coords = []
for s, blob in rows:
    coord = np.frombuffer(blob, dtype=np.float32)
    if coord.shape[0] == 248:
        strings.append(s)

`

# scratch\check_db_nans.py
`python
import sqlite3
import numpy as np

db_path = "checkpoints/geometry_registry.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

cursor.execute("SELECT text_lemma, coordinate_blob FROM geometry_registry WHERE coordinate_blob IS NOT NULL AND coordinate_blob != X''")
rows = cursor.fetchall()

nan_count = 0
inf_count = 0
for lemma, blob in rows:
    coord = np.frombuffer(blob, dtype=np.float32)
    if np.isnan(coord).any():
        if nan_count < 10:
            print(f"NaN in lemma: {lemma}")
        nan_count += 1
    elif np.isinf(coord).any():
        if inf_count < 10:

`

# scratch\check_devices.py
`python
import sys
import os

if sys.platform == "win32":
    intel_dirs = [
        r"C:\Program Files (x86)\Intel\oneAPI\compiler\latest\bin",
        r"C:\Program Files (x86)\Intel\oneAPI\tbb\latest\bin",
    ]
    for d in intel_dirs:
        if os.path.exists(d):
            try:
                os.add_dll_directory(d)
            except Exception:
                pass

import geomath

print("========================================")
print(geomath.get_all_devices())
print("========================================")

`

# scratch\check_nans.py
`python
import sys
import os
import numpy as np

sys.path.append(os.path.dirname(__file__))
from core.agent_core import AgentCore
from core.training_engine import TrainingEngine

agent = AgentCore()
engine = TrainingEngine(agent)

# Dummy data
B, L, max_bytes = 1, 4, 16
inputs = np.random.randint(0, 255, (B, L, max_bytes), dtype=np.uint8)
targets = np.random.randint(0, 255, (B, L, max_bytes), dtype=np.uint8)

for step in range(20):
    loss, g_norm, _, _, _, _ = engine.train_step(np.concatenate([inputs, targets], axis=1)[:, :5], 0, step)
    print(f"Step {step} - Loss: {loss:.4f}  Norm: {g_norm}")

`

# scratch\check_registry.py
`python
import winreg

try:
    key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Khronos\OpenCL\Vendors")
    print("OpenCL Vendors registered in Windows:")
    for i in range(100):
        try:
            name, value, type = winreg.EnumValue(key, i)
            print(f" - {name}: {value}")
        except OSError:
            break
except Exception as e:
    print("Could not read registry:", e)

`

# scratch\check_vectors.py
`python
import sqlite3
import numpy as np

conn = sqlite3.connect("checkpoints/geometry_registry.db")
cursor = conn.cursor()
cursor.execute("SELECT text_lemma, coordinate_blob FROM geometry_registry WHERE coordinate_blob IS NOT NULL")
rows = cursor.fetchall()

unique_vectors = set()
zero_vectors = 0
nan_vectors = 0
word_norms = {}

for s, blob in rows:
    coord = np.frombuffer(blob, dtype=np.float32)
    if coord.shape[0] == 248:
        # Check if exactly zero
        if np.all(coord == 0):
            zero_vectors += 1
        # Check if NaN

`

# scratch\debug_alignment.py
`python
import torch
import sqlite3
import numpy as np
from scipy.spatial import cKDTree
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.agent_core import AgentCore
from core.blt_tokenizer import BLTTokenizer
from core.bcen import ByteCoordinateEncoder

print("Loading KD-Tree...")
conn = sqlite3.connect("checkpoints/geometry_registry.db")
cursor = conn.cursor()
cursor.execute("SELECT text_lemma, coordinate_blob FROM geometry_registry WHERE coordinate_blob IS NOT NULL")
rows = cursor.fetchall()
strings = []
coords = []

`

# scratch\debug_forward.py
`python
import sys
import os
import numpy as np

sys.path.append(os.path.dirname(__file__))
from core.agent_core import AgentCore
from core.training_engine import TrainingEngine

agent = AgentCore()

# Dummy data
B, L, max_bytes = 1, 8, 256
inputs = np.random.randint(0, 255, (B, L, max_bytes), dtype=np.uint8)
targets = np.random.randint(0, 255, (B, L, max_bytes), dtype=np.uint8)

# Forward pass
out_tensor = agent.engine.forward(inputs, B, L, max_bytes)
out_np = out_tensor.numpy()

# BCEN forward

`

# scratch\delete_blt.py
`python
import os

files_to_delete = [
    "core/blt_tokenizer.py",
    "csrc/bcen.cpp",
    "csrc/bcen.h"
]

for f in files_to_delete:
    path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), f)
    if os.path.exists(path):
        os.remove(path)
        print(f"Deleted {path}")
    else:
        print(f"Not found: {path}")

`

# scratch\download_hpp.py
`python
import urllib.request
import os

def download_opencl_hpp():
    os.makedirs('csrc/CL', exist_ok=True)
    url = 'https://raw.githubusercontent.com/KhronosGroup/OpenCL-CLHPP/main/include/CL/opencl.hpp'
    print(f"Downloading {url} to csrc/CL/opencl.hpp...")
    urllib.request.urlretrieve(url, 'csrc/CL/opencl.hpp')
    print("Download complete!")

if __name__ == '__main__':
    download_opencl_hpp()

`

# scratch\extract.py
`python
import gzip
import json
import os

path = r"c:\Users\rich-\source\repos\GeoMind\trainingdata\academic\physh_raw.json.gz"
if not os.path.exists(path):
    print(f"File not found: {path}")
else:
    with gzip.open(path, 'rt', encoding='utf-8') as f:
        raw_data = json.load(f)
        
    if isinstance(raw_data, dict) and "@graph" in raw_data:
        raw_data = raw_data["@graph"]

    count = 0
    for item in raw_data:
        if "@id" in item:
            print(json.dumps(item, indent=2))
            count += 1
            if count >= 3:

`

# scratch\find_nvopencl.py
`python
import os

print("Searching for NVIDIA OpenCL DLLs...")

search_dirs = [
    r"C:\Windows\System32",
    r"C:\Windows\System32\DriverStore\FileRepository"
]

found = []
for d in search_dirs:
    print(f"Scanning {d}...")
    for root, dirs, files in os.walk(d):
        for f in files:
            if f.lower() in ["nvopencl64.dll", "nvopencl.dll", "OpenCL.dll"]:
                full_path = os.path.join(root, f)
                if "nvopencl" in f.lower():
                    found.append(full_path)

print("\n--- FOUND NVIDIA OPENCL DLLS ---")

`

# scratch\find_weight.py
`python
import email
from bs4 import BeautifulSoup

mhtml_path = r'C:\Users\rich-\source\repos\GeoMind\Documentation\Maximal Subgroups of E8 - Google Gemini.mhtml'

with open(mhtml_path, 'r', encoding='utf-8', errors='ignore') as f:
    msg = email.message_from_file(f)
    
text = ''
for part in msg.walk():
    if part.get_content_type() == 'text/html':
        payload = part.get_payload(decode=True)
        if payload:
            text += payload.decode('utf-8', errors='ignore')

soup = BeautifulSoup(text, 'html.parser')
plain_text = soup.get_text('\n', strip=True)

for i, line in enumerate(plain_text.splitlines()):
    if 'weight' in line.lower() or 'coordinate' in line.lower() or 'parameter' in line.lower():

`

# scratch\inspect_db.py
`python
import sqlite3
import os

db_path = os.path.join(os.getcwd(), 'checkpoints', 'geometry_registry.db')
print(f"Connecting to {db_path}")

try:
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute('SELECT COUNT(*) FROM geometry_registry')
    print('Total nodes:', c.fetchone()[0])
    
    c.execute('SELECT COUNT(*) FROM geometry_registry WHERE parent_hash IS NULL')
    print('Root nodes:', c.fetchone()[0])
    
    c.execute('SELECT text_lemma, parent_hash FROM geometry_registry WHERE parent_hash IS NULL LIMIT 5')
    print('Sample roots:', c.fetchall())
except Exception as e:
    print("Error:", e)

`

# scratch\inspect_engine.py
`python
import geomath
engine = geomath.GeoMindEngine()
print(dir(engine))
for name, tensor in engine.get_parameters().items():
    print(name, tensor.shape())

`

# scratch\inspect_physh.py
`python
import gzip
import json

path = r"c:\Users\rich-\source\repos\GeoMind\trainingdata\academic\physh_raw.json.gz"
with gzip.open(path, 'rt', encoding='utf-8') as f:
    data = json.load(f)

print(type(data))
if isinstance(data, list):
    print(len(data))
    print(data[:2])
elif isinstance(data, dict):
    print(list(data.keys())[:5])
    if "@graph" in data:
        print("Found @graph with length:", len(data["@graph"]))
        print(data["@graph"][:2])

`

# scratch\inspect_tensor.py
`python
import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import numpy as np
from core.e8_engine import GeoMindHybridEngine

engine = GeoMindHybridEngine()
B, L, max_bytes = 8, 256, 16
byte_data = np.zeros((B, L, max_bytes), dtype=np.uint8)
out_tensor = engine.forward(byte_data, B, L, max_bytes)
out_np = out_tensor.numpy()
print(f"out_tensor shape from C++: {out_tensor.shape()}")
print(f"out_np shape from numpy(): {out_np.shape}")
print(f"out_np size: {out_np.size}")

`

# scratch\patch_checkpoint.py
`python
import torch
import os

ckpt_path = "checkpoints/e8_agent_model.pt"

if os.path.exists(ckpt_path):
    print(f"Loading {ckpt_path} to zero out coord_head weights...")
    ckpt = torch.load(ckpt_path, map_location='cpu', weights_only=False)
    
    state_dict = ckpt['model_state_dict'] if 'model_state_dict' in ckpt else ckpt
    
    for key in list(state_dict.keys()):
        if 'coord_head.net.2.weight' in key or 'coord_head.net.2.bias' in key:
            print(f"Zeroing {key}...")
            state_dict[key].zero_()
            
    torch.save(ckpt, ckpt_path)
    print("Checkpoint patched successfully!")
else:
    print("Checkpoint not found.")

`

# scratch\query_hierarchy.py
`python
import os
import sys
import sqlite3

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
db_path = os.path.join(_ROOT, "checkpoints", "geometry_registry.db")

def query_word(lemma: str):
    if not os.path.exists(db_path):
        print("Database not found!")
        return

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Find the exact word
    cursor.execute("SELECT coordinate_hash, text_lemma, parent_hash, synset_id FROM geometry_registry WHERE text_lemma = ?", (lemma,))
    rows = cursor.fetchall()

    if not rows:

`

# scratch\run_debug.py
`python
import numpy as np
import geomath
import os
import sys

def main():
    engine = geomath.HybridEngine(0)
    B = 1
    L = 1024
    max_bytes = 10
    
    # Initialize some fake inputs
    inputs = np.random.randint(0, 256, (B, L, max_bytes), dtype=np.uint8)
    targets = np.random.randint(0, 256, (B, L, max_bytes), dtype=np.uint8)
    
    for step in range(25):
        engine.zero_grad()
        out = engine.forward(inputs, B, L, max_bytes)
        loss = engine.compute_loss_and_backward(targets, B, L, max_bytes)
        engine.step()

`

# scratch\schema.py
`python
import sqlite3
import os

db_path = r"c:\Users\rich-\source\repos\GeoMind\checkpoints\geometry_registry.db"

if not os.path.exists(db_path):
    print("Database not found.")
else:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("SELECT sql FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    for table in tables:
        print(table[0])
    conn.close()

`

# scratch\test.py
`python
import geomath
print(geomath.__file__)
print(geomath.GeoMindEngine.__init__.__doc__)

`

# scratch\test_blt.py
`python
import os
import sys

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, _ROOT)

from core.blt_tokenizer import BLTTokenizer

def main():
    print("Loading BLT Tokenizer...")
    try:
        tokenizer = BLTTokenizer()
    except FileNotFoundError as e:
        print(f"Error: {e}")
        return

    test_strings = [
        "The quick foxes jumped over the pseudo-scientific apparatus.",
        "Unbelievable! This is a test of the BLT Tokenizer's capability.",
        "print('Hello World! 😊')",

`

# scratch\test_cwn.py
`python
import sys
import os
import numpy as np

# Ensure parent directory is in path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.word_tokenizer import WordTokenizer

def test_cwn():
    print("Loading tokenizer (this will load geometry_registry.db and cwn_baseline.json)...")
    tokenizer = WordTokenizer()
    
    # Test a formal word
    formal_word = "suspicious"
    print(f"\nTesting formal word: '{formal_word}'")
    coords, ics = tokenizer.encode(formal_word)
    if coords.shape[0] > 0:
        print(f"✅ Resolved '{formal_word}': IC = {ics[0]:.4f}")
    else:

`

# scratch\test_geomath.py
`python
import os
import sys

if sys.platform == "win32":
    intel_dirs = [
        r"C:\Program Files (x86)\Intel\oneAPI\compiler\latest\bin",
        r"C:\Program Files (x86)\Intel\oneAPI\tbb\latest\bin",
    ]
    for d in intel_dirs:
        if os.path.exists(d):
            os.add_dll_directory(d)

import geomath
import numpy as np

print("Geomath imported successfully!")

# Test Tensor
t = geomath.Tensor([10, 10])
print(f"Tensor shape: {t.shape()}, numel: {t.numel()}")

`

# scratch\test_geomath_wrapper.py
`python
import torch
from core.geomath_wrapper import SYCLLinear, SYCLReLU

def test_wrapper():
    print("Testing PyTorch -> SYCL -> PyTorch wrapper...")
    
    # 1. Create a dummy tensor that mimics a batch of 248D continuous tokens
    x = torch.randn(2, 64, 248, requires_grad=True)
    
    # 2. Instantiate the SYCL-backed neural network layers
    linear1 = SYCLLinear(248, 512)
    relu = SYCLReLU()
    linear2 = SYCLLinear(512, 248)
    
    # 3. Forward Pass: PyTorch automatically offloads computation to the Intel oneAPI backend
    out1 = linear1(x)
    out_relu = relu(out1)
    final_out = linear2(out_relu)
    
    print(f"Forward pass successful. Output shape: {final_out.shape}")

`

# scratch\test_lattice.py
`python
import os
import sys
import torch

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.bcen import ByteCoordinateEncoder
from core.e8_lattice import SemanticLattice
from core.blt_tokenizer import BLTTokenizer

def main():
    print("Loading Semantic Lattice...")
    lattice = SemanticLattice()
    lattice.connect()
    
    print("Loading Tokenizer...")
    tokenizer = BLTTokenizer()
    
    print("Loading BCEN...")
    bcen = ByteCoordinateEncoder()

`

# scratch\test_math_primitives.py
`python
import os
import sys
import numpy as np

if sys.platform == "win32":
    intel_dirs = [
        r"C:\Program Files (x86)\Intel\oneAPI\compiler\latest\bin",
        r"C:\Program Files (x86)\Intel\oneAPI\tbb\latest\bin",
    ]
    for d in intel_dirs:
        if os.path.exists(d):
            try:
                os.add_dll_directory(d)
            except Exception:
                pass

import geomath

def test_primitives():
    print("========================================")

`

# scratch\test_multi_gpu.py
`python
import geomath
import numpy as np

def main():
    print("========================================")
    print("Testing Multi-GPU Hardware Mounting...")
    print("========================================")
    
    info = geomath.get_device_info()
    print("Active Hardware Mounts:")
    print(info)
    
    # 1. Create a tensor on NVIDIA (Device 0)
    print("Testing NVIDIA (Device 0) Matmul...")
    np_A = np.random.randn(2, 64, 128).astype(np.float32)
    np_B = np.random.randn(2, 128, 64).astype(np.float32)
    
    A_gpu0 = geomath.Tensor(list(np_A.shape), 0)
    B_gpu0 = geomath.Tensor(list(np_B.shape), 0)
    

`

# scratch\test_nan_loss.py
`python
import numpy as np

target = np.random.rand(1, 8, 248)
out = np.full((1, 8, 248), np.nan)

loss = np.mean((out - target)**2)
print(f"Loss: {loss:.4f}")

`

# scratch\test_urls.py
`python
import urllib.request
import urllib.error

urls = [
    "https://raw.githubusercontent.com/TIBHannover/MSC2020_SKOS/master/msc2020.ttl",
    "https://raw.githubusercontent.com/TIBHannover/MSC2020_SKOS/main/msc2020.ttl",
    "https://raw.githubusercontent.com/physh-org/PhySH/master/physh.json",
    "https://raw.githubusercontent.com/physh-org/PhySH/main/physh.json"
]

for url in urls:
    try:
        req = urllib.request.Request(url, method="HEAD")
        urllib.request.urlopen(req)
        print(f"200 OK: {url}")
    except urllib.error.HTTPError as e:
        print(f"{e.code} Error: {url}")

`

# scratch\test_zeros.py
`python
import os
os.add_dll_directory(r"C:\Program Files (x86)\Intel\oneAPI\compiler\latest\bin")
os.add_dll_directory(r"C:\Program Files (x86)\Intel\oneAPI\tbb\latest\bin")

import numpy as np
import geomath

engine = geomath.GeoMindEngine()

B, L, max_bytes = 1, 10, 16
inputs = np.random.randint(0, 255, (B, L, max_bytes), dtype=np.uint8)
targets = np.random.randint(0, 255, (B, L, max_bytes), dtype=np.uint8)

print("Forward Inputs...")
out = engine.forward(inputs, B, L, max_bytes)
out_np = out.numpy()

print("BCEN Targets...")
tgt = engine.bcen_forward(targets, B, L, max_bytes)
tgt_np = tgt.numpy()

`

# scratch\verify.py
`python
import torch
import os
import sys
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.agent_core import AgentCore
from core.blt_tokenizer import BLTTokenizer
from core.bcen import ByteCoordinateEncoder

print("Loading tokenizer and agent...")
tokenizer = BLTTokenizer()
bcen = ByteCoordinateEncoder()
device = "cpu"
agent = AgentCore().to(device)
agent.eval()

ckpt_path = "checkpoints/e8_agent_model.pt"
if os.path.exists(ckpt_path):
    print("Loading weights...")
    ckpt = torch.load(ckpt_path, map_location=device, weights_only=False)

`