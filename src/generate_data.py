import random
import csv
import os


def generate_matrix(n, filename):
    matrix = []

    for i in range(n):
        row = [0] * n
        off_diagonal_sum = 0

        # Generate off-diagonal elements
        for j in range(n):
            if i != j:
                value = random.randint(-10, 10)
                row[j] = value
                off_diagonal_sum += abs(value)

        # Make the matrix strictly diagonally dominant
        row[i] = off_diagonal_sum + random.randint(1, 10)

        matrix.append(row)

    with open(filename, "w", newline="") as file:
        writer = csv.writer(file)
        writer.writerows(matrix)

    print(f"Created {filename}")


def generate_vector(n, filename):
    with open(filename, "w", newline="") as file:
        writer = csv.writer(file)

        for _ in range(n):
            writer.writerow([100])

    print(f"Created {filename}")


os.makedirs("data", exist_ok=True)

generate_matrix(1000, "data/A_1000.csv")
generate_vector(1000, "data/B_1000.csv")

generate_matrix(2000, "data/A_2000.csv")
generate_vector(2000, "data/B_2000.csv")

print("All input files generated successfully.")
