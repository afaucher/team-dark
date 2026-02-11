from stable_baselines3 import PPO
model = PPO.load("logs/checkpoints/ppo_model_480000_steps.zip")
print(f"Observation space: {model.observation_space}")
print(f"Action space: {model.action_space}")
