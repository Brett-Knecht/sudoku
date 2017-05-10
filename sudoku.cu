#include <stdio.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <math.h>
#include <iomanip>
#include <sys/time.h>
#include <string>

// UNASSIGNED is used for empty cells in sudoku grid
#define UNASSIGNED 0

// N is used for size of Sudoku grid. Size will be NxN
#define N 9

// This function finds an entry in grid that is still unassigned
__host__ __device__ bool FindUnassignedLocation(int grid[N][N], int &row, int &col);

// Checks whether it will be legal to assign num to the given row,col
__host__ __device__ bool isSafe(int grid[N][N], int row, int col, int num);

/* Takes a partially filled-in grid and attempts to assign values to
all unassigned locations in such a way to meet the requirements
for Sudoku solution (non-duplication across rows, columns, and boxes) */
__host__ __device__ bool SolveSudoku(int grid[N][N])
{
// printf("Entered Solve Function \n");
        int row, col;

        // If there is no unassigned location, we are done
        if (!FindUnassignedLocation(grid, row, col))
        {
                return true; // success!
        }

                                         // consider digits 1 to 9
        for (int num = 1; num <= 9; num++)
        {
//      printf("Entered for loop :: num %d :: row %d :: col %d \n",num,row,col);
                // if looks promising
                if (isSafe(grid, row, col, num))
                {
//              printf("Entered If block ::num %d :: row %d :: col %d \n",num,row,col);
                        // make tentative assignment
                        grid[row][col] = num;

                        // return, if success, yay!
                        if (SolveSudoku(grid))
                        {
//                      printf("Entered second If block ::num %d :: row %d :: col %d \n",num,row,col);
                                return true;
                        }

                        // failure, unmake & try again
                        grid[row][col] = UNASSIGNED;
                }
        }
        return false; // this triggers backtracking
}

/* Searches the grid to find an entry that is still unassigned. If
found, the reference parameters row, col will be set the location
that is unassigned, and true is returned. If no unassigned entries
remain, false is returned. */
__host__ __device__ bool FindUnassignedLocation(int grid[N][N], int &row, int &col)
{
        for (row = 0; row < N; row++)
                for (col = 0; col < N; col++)
                        if (grid[row][col] == UNASSIGNED)
                                return true;
        return false;
}

/* Returns a boolean which indicates whether any assigned entry
in the specified row matches the given number. */
__host__ __device__ bool UsedInRow(int grid[N][N], int row, int num)
{
        for (int col = 0; col < N; col++)
                if (grid[row][col] == num)
                        return true;
        return false;
}

/* Returns a boolean which indicates whether any assigned entry
in the specified column matches the given number. */
__host__ __device__ bool UsedInCol(int grid[N][N], int col, int num)
{
        for (int row = 0; row < N; row++)
                if (grid[row][col] == num)
                        return true;
        return false;
}

/* Returns a boolean which indicates whether any assigned entry
within the specified 3x3 box matches the given number. */
__host__ __device__ bool UsedInBox(int grid[N][N], int boxStartRow, int boxStartCol, int num)
{
        for (int row = 0; row < 3; row++)
                for (int col = 0; col < 3; col++)
                        if (grid[row + boxStartRow][col + boxStartCol] == num)
                                return true;
        return false;
}

/* Returns a boolean which indicates whether it will be legal to assign
num to the given row,col location. */
__host__ __device__ bool isSafe(int grid[N][N], int row, int col, int num)
{
        /* Check if 'num' is not already placed in current row,
        current column and current 3x3 box */
        return !UsedInRow(grid, row, num) &&
                !UsedInCol(grid, col, num) &&
                !UsedInBox(grid, row - row % 3, col - col % 3, num);
}

/* A utility function to print grid */
__host__ __device__ void printGrid(int grid[N][N])
{
        for (int row = 0; row < N; row++)
        {
                for (int col = 0; col < N; col++)
                        printf("%2d", grid[row][col]);
                printf("\n");
        }
}

void checkErrors(const char label[])
{
  // we need to synchronise first to catch errors due to
  // asynchroneous operations that would otherwise
  // potentially go unnoticed

  cudaError_t err;

  err = cudaThreadSynchronize();
  if (err != cudaSuccess)
  {
    char *e = (char*) cudaGetErrorString(err);
    fprintf(stderr, "CUDA Error: %s (at %s)", e, label);
  }

  err = cudaGetLastError();
  if (err != cudaSuccess)
  {
    char *e = (char*) cudaGetErrorString(err);
    fprintf(stderr, "CUDA Error: %s (at %s)", e, label);
  }
}

__global__ void sudokuSolve(int matrix[N][N],bool result)
{
//printf(" Entered Global function :: result :: %d \n",result);
int blockRow;
int blockCol;
                //int blockRow = blockIdx.y;
                //int blockCol = blockIdx.x;

                // If there is no unassigned location, we are done
                if (!FindUnassignedLocation(matrix, blockRow, blockCol))
                {
                        result = true; // success!
                        return;
                }

                                                 // consider digits 1 to 9
                for (int num = 1; num <= 9; num++)
                {
//              printf(" Entered For Loop in Global :: num %d :: row %d ::col %d \n",num,blockRow,blockCol);
                        // if looks promising
                        if (isSafe(matrix, blockRow, blockCol, num))
                        {
//                      printf(" Entered If Block in Global \n");
                                // make tentative assignment
                                matrix[blockRow][blockCol] = num;

                                // return, if success, yay!
                                if (SolveSudoku(matrix))
                                {
                                        result = true;
                                        return;
                                }

                                // failure, unmake & try again
                                matrix[blockRow][blockCol] = UNASSIGNED;


                //int blockCol = blockIdx.x;

                // If there is no unassigned location, we are done
                if (!FindUnassignedLocation(matrix, blockRow, blockCol))
                {
                        result = true; // success!
                        return;
                }

                                                 // consider digits 1 to 9
                for (int num = 1; num <= 9; num++)
                {
//              printf(" Entered For Loop in Global :: num %d :: row %d ::col %d \n",num,blockRow,blockCol);
                        // if looks promising
                        if (isSafe(matrix, blockRow, blockCol, num))
                        {
//                      printf(" Entered If Block in Global \n");
                                // make tentative assignment
                                matrix[blockRow][blockCol] = num;

                                // return, if success, yay!
                                if (SolveSudoku(matrix))
                                {
                                        result = true;
                                        return;
                                }

                                // failure, unmake & try again
                                matrix[blockRow][blockCol] = UNASSIGNED;
                        }
                }
                result = false; // this triggers backtracking // maybe
                return;

}

// BEGIN: timing and error checking routines (do not modify)

// Returns the current time in microseconds
long long start_timer() {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        return tv.tv_sec * 1000000 + tv.tv_usec;
}


// Prints the time elapsed since the specified time
long long stop_timer(long long start_time, std::string name) {
        struct timeval tv;
        gettimeofday(&tv, NULL);
        long long end_time = tv.tv_sec * 1000000 + tv.tv_usec;
        std::cout << std::setprecision(5);
        std::cout << name << ": " << ((float) (end_time - start_time)) / (1000 * 1000) << " sec\n";
        return end_time - start_time;
}


/* Driver Program to test above functions */
int main()
{
        // 0 means unassigned cells
        int grid[N][N] = {
        { 3, 0, 6, 5, 0, 8, 4, 0, 0 },
        { 5, 2, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 8, 7, 0, 0, 0, 0, 3, 1 },
        { 0, 0, 3, 0, 1, 0, 0, 8, 0 },
        { 9, 0, 0, 8, 6, 3, 0, 0, 5 },
        { 0, 5, 0, 0, 9, 0, 6, 0, 0 },
        { 1, 3, 0, 0, 0, 0, 2, 5, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 7, 4 },
        { 0, 0, 5, 2, 0, 6, 3, 0, 0 } };

        // coppyof first to use for parallel because serial changes original data
        int grid2[N][N] = {
        { 3, 0, 6, 5, 0, 8, 4, 0, 0 },
        { 5, 2, 0, 0, 0, 0, 0, 0, 0 },
        { 0, 8, 7, 0, 0, 0, 0, 3, 1 },
        { 0, 0, 3, 0, 1, 0, 0, 8, 0 },
        { 9, 0, 0, 8, 6, 3, 0, 0, 5 },
        { 0, 5, 0, 0, 9, 0, 6, 0, 0 },
        { 1, 3, 0, 0, 0, 0, 2, 5, 0 },
        { 0, 0, 0, 0, 0, 0, 0, 7, 4 },
        { 0, 0, 5, 2, 0, 6, 3, 0, 0 } };

        printf("***********Input Puzzle*********** \n");
        printGrid(grid);
long long CPU_start_time = start_timer();
        if (SolveSudoku(grid) == true)
        {
                printf("*******Serial Solved Puzzle******* \n");
                printGrid(grid);
        }
        else
                printf("No solution exists");
 long long CPU_time = stop_timer(CPU_start_time, "CPU Run Time");

///////////////////////////////////////// Cuda ////////////////////////////////

        // set up variables
        int d_matrix[N][N];
        bool *cudaresult;
        bool *d_result;
long long GPU_start_time = start_timer();

        //set up gpu memory
        cudaMalloc((void**)&d_matrix, (1*sizeof(int)));
        cudaMalloc((void**)&d_result, (1*sizeof(bool)));
        //checkErrors("The Mallocs \n");

        // put the data into gpu memory
        cudaMemcpy(d_matrix, grid, (1*sizeof(int)), cudaMemcpyHostToDevice);
        //checkErrors("The Memcopy 1-1 matrix \n");
        cudaMemcpy(d_result, cudaresult, (1*sizeof(bool)), cudaMemcpyHostToDevice);
        //checkErrors("The Memcopys 1-2 result \n");

        // run the kernal
        sudokuSolve<< <1, 1>> >(d_matrix,d_result);
        //checkErrors("The kernal \n");

        // copy back memory from GPU to CPU
        cudaMemcpy(grid, d_matrix, (81*sizeof(int)), cudaMemcpyDeviceToHost);
        //checkErrors("The Memcopys 2-1 matrix \n");
        cudaMemcpy(cudaresult, d_result, (1*sizeof(bool)), cudaMemcpyDeviceToHost);
        //checkErrors("The Memcopys 2-2 result \n");


        // print out parellel solved puzzle
        printf("********CUDA Solved Puzzle******** \n");
        printGrid(grid);

 long long GPU_starttime_endtimer = stop_timer(GPU_start_time, "GPU Total run time ");
        cudaFree(d_matrix);
        cudaFree(d_result);


        return 0;
}
