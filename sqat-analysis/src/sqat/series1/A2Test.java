package sqat.series1;


public class A2Test {

	
	// paths: 4
	public void nested() {
		if (true) {
			if (true) {
				if (true) {
					
				}
			}
		}
	}
	
	// paths: 2
	public void if_else() {
		int a = 0;
		if (a > 0) {
			
		} else {
			
		}
	}
	
	// paths: 5
	public void switch_case() {
		switch (1) {
		case 0:		break;
		case 1:		break;
		case 2:		break;
		default:	break;
		}
	}
	
	// paths: 3
	public void infix_simple() {
		if (true && true) {
		}
	}
	
	// paths: 5
	public void infix_complex() {
		int a = 0, b = 0, c = 0, d = 0;
		if (a == 1 && b == 2 || c == 3 && d == 4) {
		}
	}
	
	// paths: 
	public void try_catch() {
		
		try {
		}
		catch (Exception e) {
			
		}
	}
}