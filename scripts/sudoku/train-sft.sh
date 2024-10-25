export WANDB_DISABLED=true

exp=output/sudoku/gpt2-model-bs1024-lr1e-3-ep100-`date "+%Y%m%d-%H%M%S"`
mkdir -p $exp

CUDA_VISIBLE_DEVICES=0,1,2,3,4,5,6,7 \
accelerate launch --multi_gpu --num_machines 1 --mixed_precision fp16 --num_processes 8 \
src/train_bash.py \
    --stage sft --overwrite_output_dir \
    --cache_dir ./cache \
    --model_name_or_path model_config_tiny \
    --do_train \
    --dataset sudoku_train \
    --finetuning_type full \
    --cutoff_len 164 \
    --output_dir $exp \
    --overwrite_cache \
    --per_device_train_batch_size 128 \
    --gradient_accumulation_steps 1 \
    --lr_scheduler_type cosine \
    --logging_steps 1 \
    --val_size 448 \
    --per_device_eval_batch_size 32 \
    --evaluation_strategy steps \
    --eval_steps 100 \
    --save_steps 500 \
    --learning_rate 1e-3 \
    --num_train_epochs 100.0 \
    --plot_loss \
    --run_name ${dataset}_prefix \
    --preprocessing_num_workers 8 \
    --fp16 \
    --save_total_limit 1 \
    > $exp/train.log

for dataset in sudoku_test
do
mkdir $exp/${dataset}
CUDA_VISIBLE_DEVICES=6  \
python3 -u src/train_bash.py \
    --stage sft --overwrite_output_dir \
    --cache_dir ./cache \
    --model_name_or_path model_config_tiny \
    --do_predict \
    --cutoff_len 164 \
    --per_device_eval_batch_size 32 \
    --dataset $dataset \
    --finetuning_type full \
    --output_dir $exp/$dataset \
    --checkpoint_dir $exp \
    --predict_with_generate \
    --max_new_tokens 82 \
    > $exp/eval.log
done