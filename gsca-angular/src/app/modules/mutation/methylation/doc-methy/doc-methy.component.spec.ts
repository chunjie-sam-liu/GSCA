import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocMethyComponent } from './doc-methy.component';

describe('DocMethyComponent', () => {
  let component: DocMethyComponent;
  let fixture: ComponentFixture<DocMethyComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocMethyComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocMethyComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
