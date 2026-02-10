
import argparse
import os
import torch
from stable_baselines3 import PPO
from stable_baselines3.common.callbacks import CheckpointCallback, BaseCallback
from stable_baselines3.common.vec_env import VecMonitor
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv

class GodotMetricsCallback(BaseCallback):
    def __init__(self, verbose=0):
        super(GodotMetricsCallback, self).__init__(verbose)

    def _on_step(self) -> bool:
        # Check if an episode ended in any of the parallel environments
        dones = self.locals.get("dones")
        infos = self.locals.get("infos")
        
        if dones is not None and infos is not None:
            for i, done in enumerate(dones):
                if done:
                    info = infos[i]
                    # Extract custom metrics from Godot's get_info()
                    gems = info.get("gems_collected")
                    kills = info.get("enemies_killed")
                    damage = info.get("damage_dealt")
                    damage_taken = info.get("damage_taken")
                    dist = info.get("distance_travelled")
                    shots = info.get("shots_fired")
                    pickups = info.get("pickups_collected")
                    deaths = info.get("deaths")
                    is_dead = info.get("is_dead")
                    is_success = info.get("is_success")

                    if gems is not None:
                        self.logger.record("env/gems_collected", gems)
                    if kills is not None:
                        self.logger.record("env/enemies_killed", kills)
                    if damage is not None:
                        self.logger.record("env/damage_dealt", damage)
                    if damage_taken is not None:
                        self.logger.record("env/damage_taken", damage_taken)
                    if dist is not None:
                        self.logger.record("env/distance_travelled", dist)
                    if shots is not None:
                        self.logger.record("env/shots_fired", shots)
                    if pickups is not None:
                        self.logger.record("env/pickups_collected", pickups)
                    if deaths is not None:
                        self.logger.record("env/deaths", deaths)
                    if is_dead is not None:
                        self.logger.record("env/is_dead", is_dead)
                    if is_success is not None:
                        self.logger.record("env/is_success", is_success)
                    
                    # Smoke Test Print
                    print(f"[Verification] Episode Complete! Gems: {gems}, Kills: {kills}, Dist: {dist:.1f}, Shots: {shots}")
        return True

def train(args):
    print(f"Training with args: {args}")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"--- [Training Device: {device.upper()}] ---")
    
    # Create environment
    env = StableBaselinesGodotEnv(
        env_path=args.env_path,
        show_window=args.viz,
        speedup=args.speedup,
        n_parallel=args.n_parallel,
        seed=args.seed,
        port=args.port
    )
    env = VecMonitor(env)
    
    # Create logs directory
    log_dir = "logs/sb3"
    os.makedirs(log_dir, exist_ok=True)
    
    # PPO Hyperparameters (Tunable)
    if args.load_path and os.path.exists(args.load_path):
        print(f"Resuming training from {args.load_path}...")
        model = PPO.load(
            args.load_path, 
            env=env, 
            tensorboard_log=log_dir,
            device="cuda" if torch.cuda.is_available() else "cpu"
        )
    else:
        print("Starting training from scratch...")
        model = PPO(
            "MultiInputPolicy",
            env,
            ent_coef=0.0001,
            verbose=1,
            n_steps=2048, 
            batch_size=64,
            tensorboard_log=log_dir,
            device="cuda" if torch.cuda.is_available() else "cpu"
        )
    
    # Callback
    checkpoint_callback = CheckpointCallback(
        save_freq=max(10000 // args.n_parallel, 1), 
        save_path='logs/checkpoints/',
        name_prefix='ppo_model'
    )
    
    # Train
    print("Starting training...")
    try:
        model.learn(
            total_timesteps=args.total_timesteps,
            callback=[checkpoint_callback, GodotMetricsCallback()],
            tb_log_name="ppo_run",
            reset_num_timesteps=not args.load_path # Keep timestep count if resuming
        )
    except KeyboardInterrupt:
        print("Training interrupted by user. Saving model...")
    finally:
        print("Saving final model...")
        model.save("final_model.zip")
        model.save("latest_model.zip")
        print("Model saved to final_model.zip and latest_model.zip")
        # Export logic
        if args.export_path:
            try:
                print(f"Exporting model to {args.export_path}...")
                import subprocess
                # Ensure the models directory exists
                os.makedirs(os.path.dirname(args.export_path), exist_ok=True)
                
                # Use current python to run export script
                subprocess.run([
                    "python", "scripts/training/export_to_onnx.py",
                    "--model_path", "final_model.zip",
                    "--output_path", args.export_path
                ], check=True)
                print(f"Automatic export to {args.export_path} successful.")
            except Exception as e:
                print(f"Automatic export failed: {e}")
            
        env.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--env_path", type=str, default=None)
    parser.add_argument("--n_parallel", type=int, default=1)
    parser.add_argument("--viz", action="store_true", default=False)
    parser.add_argument("--speedup", type=int, default=20)
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--port", type=int, default=11008)
    parser.add_argument("--total_timesteps", type=int, default=1000000)
    parser.add_argument("--load_path", type=str, default=None)
    parser.add_argument("--export_path", type=str, default="models/policy.onnx")
    
    args = parser.parse_args()
    
    train(args)
