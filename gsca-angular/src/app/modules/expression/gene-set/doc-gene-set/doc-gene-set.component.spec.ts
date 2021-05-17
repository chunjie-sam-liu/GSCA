import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocGeneSetComponent } from './doc-gene-set.component';

describe('DocGeneSetComponent', () => {
  let component: DocGeneSetComponent;
  let fixture: ComponentFixture<DocGeneSetComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocGeneSetComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocGeneSetComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
