import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocGsvaSubtypeComponent } from './doc-gsva-subtype.component';

describe('DocGsvaSubtypeComponent', () => {
  let component: DocGsvaSubtypeComponent;
  let fixture: ComponentFixture<DocGsvaSubtypeComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocGsvaSubtypeComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocGsvaSubtypeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
