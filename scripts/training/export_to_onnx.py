import os
import torch
import argparse
from stable_baselines3 import PPO

class OnnxablePolicy(torch.nn.Module):
    def __init__(self, policy):
        super().__init__()
        self.policy = policy

    def forward(self, observation):
        # 1. Extract features (Handling Dict mapping for MultiInputPolicy)
        features = self.policy.extract_features({"obs": observation})
        
        # 2. Get latent representations
        latent_pi, _ = self.policy.mlp_extractor(features)
        
        # 3. Get mean action
        mean_actions = self.policy.action_net(latent_pi)
        
        return mean_actions

def export_to_onnx(model_path, output_path):
    print(f"Loading model from {model_path}...")
    # Load model on CPU
    model = PPO.load(model_path, device="cpu")
    
    # Create wrapper
    onnxable_model = OnnxablePolicy(model.policy)
    
    # Dummy input - Detect size from model
    obs_size = model.observation_space["obs"].shape[0]
    print(f"Detected observation size: {obs_size}")
    dummy_input = torch.randn(1, obs_size)
    
    print(f"Exporting to {output_path}...")
    torch.onnx.export(
        onnxable_model,
        dummy_input,
        output_path,
        opset_version=17, # Balanced compatibility
        input_names=["obs"],   # Input tensor name
        output_names=["output"], # Output tensor name
        dynamic_axes={
            "obs": {0: "batch_size"},
            "output": {0: "batch_size"}
        }
    )
    print("Export complete.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", type=str, default="final_model.zip")
    parser.add_argument("--output_path", type=str, default="models/policy.onnx")
    args = parser.parse_args()
    
    # Ensure models directory exists
    os.makedirs(os.path.dirname(args.output_path), exist_ok=True)
    
    if not os.path.exists(args.model_path):
        print(f"Error: {args.model_path} not found.")
        exit(1)
        
    export_to_onnx(args.model_path, args.output_path)
