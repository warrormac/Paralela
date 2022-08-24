#include <iostream>
#include <chrono>
#include <ctime>
#include <vector>

#define max 20000

using namespace std;
using namespace std::chrono;


vector<double> y(max, 0);
vector<vector<double>> A(max, vector<double>(max, 12));
vector<double> x(max, 15);

int main()
{
	high_resolution_clock::time_point t1 = high_resolution_clock::now();
	for (double i = 0; i < max; i++)
	{
		for (double j = 0; j < max; j++)
		{
			y[i] += A[i][j] * x[j];
		}
	}
	high_resolution_clock::time_point t2 = high_resolution_clock::now();

	duration<double> time_span = duration_cast<duration<double>>(t2 - t1);
	std::cout << "Primer For: " << time_span.count() << " segundos." << endl;

	fill(y.begin(), y.end(), 0);

	high_resolution_clock::time_point t11 = high_resolution_clock::now();
	for (double j = 0; j < max; j++)
	{
		for (double i = 0; i < max; i++)
		{
			y[i] += A[i][j] * x[j];
		}
	}
	high_resolution_clock::time_point t21 = high_resolution_clock::now();

	duration<double> duration1 = duration_cast<duration<double>>(t21 - t11);
	std::cout << "Segundo For: " << duration1.count() << " segundos." << endl;

	return 0;
}
