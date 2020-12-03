import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ImmuneExprComponent } from './immune-expr.component';

describe('ImmuneExprComponent', () => {
  let component: ImmuneExprComponent;
  let fixture: ComponentFixture<ImmuneExprComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ImmuneExprComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ImmuneExprComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
