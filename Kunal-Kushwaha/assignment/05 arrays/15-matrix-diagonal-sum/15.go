/*
15. [Matrix Diagonal Sum](https://leetcode.com/problems/matrix-diagonal-sum/)
*/

package main

import "fmt"

func main() {
	mat := [][]int{
		{5},
	}
	fmt.Println(diagonalSum(mat))
}

// solution from discussion better lesser lines!!
func diagonalSum(mat [][]int) int {

	leng := len(mat)
	mid := leng / 2
	sum := 0
	fmt.Println("leng , mid : ", leng, mid)

	for i := 0; i <= leng-1; i++ {
		sum += mat[i][i] + mat[i][leng-1-i] //main logic taking 00 11 22  for diagonal and 0 last, 0 last-1, 0 laste -2 like this for second diagonal
	}

	if leng%2 != 0 {
		sum -= mat[mid][mid]
	}
	return sum
}

// my solution

// func diagonalSum(mat [][]int) int {

// 	sumOfAllDiagonalEle := 0
// 	var diagonalEle1 = 0
// 	var diagonalEle2 = len(mat) - 1

// 	for row := 0; row <= len(mat)-1; row++ { // iterating over row

// 		for column := 0; column <= len(mat[row])-1; column++ { // iterating over column

// 			fmt.Println("daiEle1,diaEle2 :", diagonalEle1, diagonalEle2)

// 			if column == diagonalEle1 || column == diagonalEle2 { //we already know diagonal position for the current row comparing column position with the same
// 				sumOfAllDiagonalEle += mat[row][column]
// 			}
// 		}

// 		diagonalEle1++
// 		diagonalEle2--
// 	}
// 	return sumOfAllDiagonalEle
// }
