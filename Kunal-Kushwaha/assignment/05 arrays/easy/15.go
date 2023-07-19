/*
15. [Matrix Diagonal Sum](https://leetcode.com/problems/matrix-diagonal-sum/)
*/

package main

import "fmt"

func main() {
	mat := [][]int{
		{1, 2, 3, 1},
		{3, 2, 1, 1},
		{2, 3, 1, 1},
		{1, 2, 3, 1},
	}
	fmt.Println(diagonalSum(mat))
}
func diagonalSum(mat [][]int) int {

	sumOfAllDiagonalEle := 0
	var diagonalEle1 = 0
	var diagonalEle2 = len(mat) - 1

	for row := 0; row <= len(mat)-1; row++ { // iterating over row
		for column := 0; column <= len(mat[row])-1; column++ { // iterating over column
			fmt.Println("daiEle1,diaEle2 :", diagonalEle1, diagonalEle2)
			if column == diagonalEle1 || column == diagonalEle2 { //we already know diagonal position for the current row comparing column position with the same
				sumOfAllDiagonalEle += mat[row][column]
			}
		}
		diagonalEle1++
		diagonalEle2--
	}
	return sumOfAllDiagonalEle
}
