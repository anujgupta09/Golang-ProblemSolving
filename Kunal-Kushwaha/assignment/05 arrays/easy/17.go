// 17. [Transpose Matrix]
// (https://leetcode.com/problems/transpose-matrix/)

package main

import "fmt"

func main() {
	var matrix = [][]int{
		{1, 2},
		{4, 5},
		{7, 8},
	}
	fmt.Println(transpose(matrix))
}
func transpose(matrix [][]int) [][]int {

	// transposeMatrix := matrix // this just make it another reference of matrix array hence change to one changes another too
	var transposeMatrix [][]int = make([][]int, len(matrix)) // intialize array with make

	for rowIndex, row := range matrix {

		transposeMatrix[rowIndex] = make([]int, len(row)) // intialize array inside array

		for colIndex, _ := range row {

			fmt.Println("row no. :", rowIndex, " |  col no. :", colIndex)
			fmt.Println("Element at this postition : ", matrix[rowIndex][colIndex])
			transposeMatrix[rowIndex][colIndex] = matrix[colIndex][rowIndex]
			fmt.Println("------------------------------------------------")

		}
	}
	fmt.Println("matrix : ", matrix)
	return transposeMatrix
}
