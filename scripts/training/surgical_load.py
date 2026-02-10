import torch
import os
import argparse
from stable_baselines3 import PPO
import gymnasium as gym

def transfer_weights(source_path, target_save_path):
    print(f"--- Brain Surgery Strategy 2: {source_path} -> {target_save_path} ---")
    
    # 1. Create a dummy environment with the NEW observation space
    new_obs_space = gym.spaces.Dict({
        "obs": gym.spaces.Box(low=-1.0, high=1.0, shape=(102,), dtype="float32")
    })
    
    # 2. Extract weights from the old model
    # We load the weights manually to avoid the "Env mismatch" check in PPO.load
    # (Since SB3 stores weights in policy.pth)
    import zipfile
    import io
    with zipfile.ZipFile(source_path, 'r') as zio:
        policy_data = zio.read('policy.pth')
    state_dict = torch.load(io.BytesIO(policy_data), map_location='cpu')

    # 3. Initialize a NEW model with the correct architecture
    # We use a dummy env to set the spaces
    class DummyEnv(gym.Env):
        def __init__(self, obs_space):
            self.observation_space = obs_space
            # PPO flattens Dict actions into a Box usually, 
            # or Godot-RL bridge handles it. 
            # For dummy initialization, a Box of matching size works.
            self.action_space = gym.spaces.Box(low=-1.0, high=1.0, shape=(5,), dtype="float32")
        def reset(self, seed=None): return self.observation_space.sample(), {}
        def step(self, action): return self.observation_space.sample(), 0.0, False, False, {}

    new_env = DummyEnv(new_obs_space)
    new_model = PPO("MultiInputPolicy", new_env, verbose=1)
    
    # 4. Perform the Weight Mapping
    new_state_dict = new_model.policy.state_dict()
    
    # Copy all weights that match by name (most hidden layers)
    for key in state_dict.keys():
        if key in new_state_dict:
            # Check for input layer specifically
            if "mlp_extractor.policy_net.0.weight" in key or "mlp_extractor.value_net.0.weight" in key:
                print(f"Surgically remapping input layer: {key}")
                old_w = state_dict[key]
                new_w = new_state_dict[key].clone()
                
                # Knowledge transfer (90 -> 102)
                # 0..60 (Radar, Self, Mission-ish) -> Identical
                # Note: Old 'Target' at 57-60 included enemies, now 'Mission' is gems only.
                # The network will learn to distinguish this quickly.
                new_w[:, 0:61] = old_w[:, 0:61]
                
                # 61..65 is NEW (A* Path: 5 dims) - leave randomized
                
                # 66-69: Gear (Moved from 61-64)
                new_w[:, 66:70] = old_w[:, 61:65]
                # 70: Gear Type (NEW) - leave randomized
                
                # 71: Aiming At Me (Moved from 65)
                new_w[:, 71] = old_w[:, 65]
                
                # 72-83: Projs (Moved from 66-77)
                new_w[:, 72:84] = old_w[:, 66:78]
                
                # 84-95: Weapons (Moved from 78-89)
                new_w[:, 84:96] = old_w[:, 78:90]
                
                # 96..101: Padding -> Zero
                new_w[:, 96:102] = 0.0
                
                new_state_dict[key] = new_w
            else:
                # Copy identical hidden layers
                if new_state_dict[key].shape == state_dict[key].shape:
                    new_state_dict[key] = state_dict[key]
                else:
                    print(f"Skipping key {key} due to shape mismatch: {state_dict[key].shape} vs {new_state_dict[key].shape}")

    # 5. Load weights into the new model and save
    new_model.policy.load_state_dict(new_state_dict)
    new_model.save(target_save_path)
    print(f"--- Brain Surgery Complete: {target_save_path} ---")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=str, default="final_model.zip")
    parser.add_argument("--target", type=str, default="models/nav_warmstart.zip")
    args = parser.parse_args()
    
    if os.path.exists(args.source):
        transfer_weights(args.source, args.target)
    else:
        print(f"Error: Could not find {args.source}")
