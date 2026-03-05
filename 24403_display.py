def show_results(results):
    print("📊 Task Results Summary:")
    for k, v in results.items():
        if isinstance(v, list):
            print(f"{k}: {len(v)} items")
        else:
            print(f"{k}: {v}")
