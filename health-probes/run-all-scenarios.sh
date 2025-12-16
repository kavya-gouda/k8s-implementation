#!/bin/bash
set -e

echo "🧪 Running all K8s probe scenarios..."
echo ""

echo "=== Scenario 1: Bad Probes ==="
cd scenario-1-bad-probes
./run.sh
cd ..
echo ""

read -p "Press Enter to continue to Scenario 2..."

echo "=== Scenario 2: Proper Probes ==="
cd scenario-2-proper-probes
./run.sh
cd ..
echo ""

echo "✅ All scenarios deployed!"
echo "📚 Check individual scenario READMEs for testing instructions"