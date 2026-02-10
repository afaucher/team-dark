
import argparse
import os
import time
from stable_baselines3 import PPO
from godot_rl.wrappers.stable_baselines_wrapper import StableBaselinesGodotEnv

def enjoy(args):
    print("Starting environment for inference...")
    env = StableBaselinesGodotEnv(
        env_path=args.env_path,
        show_window=args.viz,
        speedup=args.speedup,
        n_parallel=1,
        seed=args.seed,
        port=args.port
    )

    print(f"Loading model from {args.model_path}...")
    model = None
    if args.model_path.endswith(".onnx"):
        import onnxruntime as ort
        import numpy as np
        
        class OnnxModel:
            def __init__(self, path):
                self.sess = ort.InferenceSession(path)
            def predict(self, obs, deterministic=True):
                if isinstance(obs, dict):
                    feed = {k: v.astype(np.float32) for k, v in obs.items()}
                else:
                    feed = {"obs": obs.astype(np.float32)}
                res = self.sess.run(None, feed)
                return res[0], None
        
        model = OnnxModel(args.model_path)
    else:
        model = PPO.load(args.model_path, env=env)

    print("Running inference loop...")
    obs = env.reset()
    try:
        while True:
            action, _states = model.predict(obs, deterministic=True)
            obs, rewards, dones, info = env.step(action)
    except KeyboardInterrupt:
        print("Stopping inference...")
    finally:
        env.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", type=str, default="final_model.zip")
    parser.add_argument("--env_path", type=str, default=None)
    parser.add_argument("--viz", action="store_true", default=False)
    parser.add_argument("--speedup", type=int, default=1)
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument("--port", type=int, default=11008)
    
    args = parser.parse_args()
    
    # Check if model exists
    if not os.path.exists(args.model_path):
         # Try looking in logs/checkpoints for latest if final not found? 
         # Or prompt user.
         pass

    enjoy(args)
