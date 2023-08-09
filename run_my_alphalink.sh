#! /bin/bash

set -e

fasta_path=$1
crosslinks=$2
output_dir_base=$3

pretrained_model_version=$4

if [[ "$pretrained_model_version" -eq 2 || "$pretrained_model_version" -eq 3 ]]; then
    pretrained_model_version=$pretrained_model_version
else
    echo "Invalid Pretrained Model Version: ${pretrained_model_version}, fixed to 3."
    pretrained_model_version=3
fi


# Path and user config (change me if required)

max_template_date=2022-10-30

data_dir=/mnt/db/
param_path=$data_dir/weights/alphalink/

bfd_database_path="$data_dir/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt"
mgnify_database_path="$data_dir/mgnify/mgy_clusters.fa"
template_mmcif_dir="$data_dir/pdb_mmcif/mmcif_files"
obsolete_pdbs_path="$data_dir/pdb_mmcif/obsolete.dat"

uniref30_database_path="$data_dir/uniref30_uc30/UniRef30_2022_02/UniRef30_2022_02"
uniref90_database_path="$data_dir/uniref90/uniref90.fasta"

uniprot_database_path="$data_dir/uniprot/uniprot.fasta"
pdb_seqres_database_path="$data_dir/pdb_seqres/pdb_seqres.txt"

# automatically determined directory
af_official_repo=$(readlink -f $(dirname $0))

echo "Starting MSA generation..."
python $af_official_repo/unifold/homo_search.py \
    --fasta_path=$fasta_path \
    --max_template_date=$max_template_date \
    --output_dir=$output_dir_base  \
    --uniref90_database_path=$uniref90_database_path \
    --mgnify_database_path=$mgnify_database_path \
    --bfd_database_path=$bfd_database_path \
    --uniclust30_database_path=$uniref30_database_path \
    --uniprot_database_path=$uniprot_database_path \
    --pdb_seqres_database_path=$pdb_seqres_database_path \
    --template_mmcif_dir=$template_mmcif_dir \
    --obsolete_pdbs_path=$obsolete_pdbs_path \
    --use_precomputed_msas=True

echo "Converting crosslinks data from $crosslinks to ${crosslinks%.csv}.pkl.gz"
python $af_official_repo/generate_crosslink_pickle.py --csv ${crosslinks} --output ${crosslinks%.csv}.pkl.gz


echo "Starting prediction..."
fasta_file=$(basename $fasta_path)
target_name=${fasta_file%.fa*}
python $af_official_repo/inference.py \
	--model_name="multimer_af2_crop" \
	--param_path=$param_path/AlphaLink-Multimer_SDA_v${pretrained_model_version}.pt \
	--data_dir=$output_dir_base \
	--target_name=$target_name \
	--output_dir=$output_dir_base \
    --crosslinks=${crosslinks%.csv}.pkl.gz \
	--bf16 \
	--use_uniprot \
	--relax
