import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocPaenComponent } from './doc-paen.component';

describe('DocPaenComponent', () => {
  let component: DocPaenComponent;
  let fixture: ComponentFixture<DocPaenComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocPaenComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocPaenComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
