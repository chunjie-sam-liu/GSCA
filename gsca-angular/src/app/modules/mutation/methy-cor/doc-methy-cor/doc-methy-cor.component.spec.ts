import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocMethyCorComponent } from './doc-methy-cor.component';

describe('DocMethyCorComponent', () => {
  let component: DocMethyCorComponent;
  let fixture: ComponentFixture<DocMethyCorComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocMethyCorComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocMethyCorComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
