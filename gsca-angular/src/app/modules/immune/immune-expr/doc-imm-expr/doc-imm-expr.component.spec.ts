import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocImmExprComponent } from './doc-imm-expr.component';

describe('DocImmExprComponent', () => {
  let component: DocImmExprComponent;
  let fixture: ComponentFixture<DocImmExprComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocImmExprComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocImmExprComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
