#!/bin/bash
set -o errexit

readonly LOG_FILE="matchmaker_ablation.log"

# Create the destination log file that we can
# inspect later if something goes wrong with the
# initialization.
sudo touch $LOG_FILE

# Make sure that the file is accessible by the user
# that we want to give permissions to read later
# (maybe this script is executed by some other user)
sudo chown ubuntu $LOG_FILE

# Open standard out at `$LOG_FILE` for write.
# This has the effect 
# Redirect standard error to standard out such that 
# standard error ends up going to wherever standard
# out goes (the file).
exec > >(tee $LOG_FILE) 2>&1

function shutdown_instance {
  echo "Something went wrong! Shutting down instance";
  sleep 60
  sudo shutdown -h
}
trap shutdown_instance ERR

# Load the chemprop conda environment
eval "$(conda shell.bash hook)"
conda activate matchmaker
for i in {30,40,60,80};
    do
    for cl in `ls ablation_data/* | cut -d/ -f2 | cut -d_ -f1 | sort -u | head -5`;
        do
        echo 'Starting training ' ${cl} ' fraction ' ${i}
        echo python main.py \
        --saved-model-name ablation_prediction/${cl}_test_inds_frac${i}.h5 \
        --comb-data-name data/DrugCombinationData.tsv \
        --cell_line-gex data/cell_line_gex.csv \
        --drug1-chemicals data/drug1_chem.csv \
        --drug2-chemicals data/drug2_chem.csv \
        --train-test-mode 1 \
        --train-ind ablation_data/${cl}_test_inds_frac${i}.txt \
        --test-ind ablation_data/${cl}_test_inds_frac${i}.txt \
        --val-ind ablation_data/${cl}_val_inds_frac${i}.txt \
        --arch architecture.txt \
        --gpu-support 1 \
        --output_prefix ablation_prediction/out_${cl}_test_inds_frac0${i}
        python main.py \
        --saved-model-name ablation_prediction/${cl}_test_inds_frac${i}.h5 \
        --comb-data-name data/DrugCombinationData.tsv \
        --cell_line-gex data/cell_line_gex.csv \
        --drug1-chemicals data/drug1_chem.csv \
        --drug2-chemicals data/drug2_chem.csv \
        --train-test-mode 1 \
        --train-ind ablation_data/${cl}_train_inds_frac${i}.txt \
        --test-ind ablation_data/${cl}_test_inds_frac${i}.txt \
        --val-ind ablation_data/${cl}_val_inds_frac${i}.txt \
        --arch architecture.txt \
        --gpu-support 1 \
        --output_prefix ablation_prediction/out_${cl}_test_inds_frac${i}
        echo 'Finished training'
        for pcl in `ls ablation_data/* | cut -d/ -f2 | cut -d_ -f1 | sort -u | head -5`;
            do
                echo 'Starting transfer prediction ' ${cl} '->' ${pcl} ', with fraction ' ${i}
                echo python main.py \
                --saved-model-name ablation_prediction/${cl}_test_inds_frac${i}.h5 \
                --comb-data-name data/DrugCombinationData.tsv \
                --cell_line-gex data/cell_line_gex.csv \
                --drug1-chemicals data/drug1_chem.csv \
                --drug2-chemicals data/drug2_chem.csv \
                --train-test-mode 0 \
                --train-ind ablation_data/${cl}_test_inds_frac${i}.txt \
                --test-ind ablation_data/${pcl}_inds.txt \
                --val-ind ablation_data/${cl}_val_inds_frac${i}.txt \
                --arch architecture.txt \
                --gpu-support 1 \
                --output_prefix ablation_prediction/transfer_${cl}_to_${pcl}_frac_${i}
                python main.py \
                --saved-model-name ablation_prediction/${cl}_test_inds_frac${i}.h5 \
                --comb-data-name data/DrugCombinationData.tsv \
                --cell_line-gex data/cell_line_gex.csv \
                --drug1-chemicals data/drug1_chem.csv \
                --drug2-chemicals data/drug2_chem.csv \
                --train-test-mode 0 \
                --train-ind ablation_data/${cl}_train_inds_frac${i}.txt \
                --test-ind ablation_data/${pcl}_inds.txt \
                --val-ind ablation_data/${cl}_val_inds_frac${i}.txt \
                --arch architecture.txt \
                --gpu-support 1 \
                --output_prefix ablation_prediction/transfer_${cl}_to_${pcl}_frac_${i}
            done
        done
    done
echo Ending time
date
sudo shutdown -h
